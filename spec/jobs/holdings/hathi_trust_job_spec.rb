require 'rails_helper'
require 'support/holdings_contexts'

module Holdings
  describe HathiTrustJob, type: :job do
    include_context('HoldingsTask')

    describe 'success' do
      let(:batch_size) { BerkeleyLibrary::Holdings::HathiTrust::RecordUrlBatchRequest::MAX_BATCH_SIZE }

      let(:batches) { oclc_numbers_expected.each_slice(batch_size).to_a }
      let(:batch_uris) { batches.map { |batch| BerkeleyLibrary::Holdings::HathiTrust::RecordUrlBatchRequest.new(batch).uri } }
      let(:batch_json_bodies) { Array.new(batches.size) { |i| File.read("spec/data/holdings/hathi_trust/ht-batch-#{i}.json") } }

      before do
        @ht_queue_adapter = HathiTrustJob.queue_adapter
        HathiTrustJob.queue_adapter = :inline
      end

      after do
        HathiTrustJob.queue_adapter = @ht_queue_adapter
      end

      describe :perform do
        it 'rejects a non-HathiTrust task' do
          task.update(hathi: false)

          expect { HathiTrustJob.perform_now(task) }.to raise_error(ArgumentError)
        end

        it 'retrieves record URLs' do

          batch_uris.each_with_index do |batch_uri, i|
            batch_json_body = batch_json_bodies[i]
            stub_request(:get, batch_uri).to_return(body: batch_json_body)
          end

          HathiTrustJob.perform_now(task)

          task_records = task.holdings_records
          expected_count = record_urls_expected.size
          expect(task_records.where(ht_retrieved: true).count).to eq(expected_count)
          expect(task_records.where(ht_retrieved: false)).not_to exist
          expect(task_records.where.not(ht_error: nil)).not_to exist

          expect(task.hathi_incomplete?).to eq(false)

          aggregate_failures do
            task_records.find_each do |ht_record|
              oclc_num = ht_record.oclc_number
              url_expected = record_urls_expected[oclc_num]
              url_actual = ht_record.ht_record_url
              expect(url_actual).to eq(url_expected), "OCLC #{oclc_num}: expected #{url_expected.inspect}, was #{url_actual.inspect}"
            end
          end
        end

        it 'completes partially-completed jobs' do
          task_records = task.holdings_records

          batch_uris.each_with_index do |batch_uri, i|
            batch_json_body = batch_json_bodies[i]
            if i.odd?
              stub_request(:get, batch_uri).to_return(body: batch_json_body)
            else
              # Simulate previously-completed partial job
              batches[i].each do |oclc_number|
                ht_record_url = record_urls_expected[oclc_number]
                record = task_records.find_by!(oclc_number:)
                record.update(ht_retrieved: true, ht_record_url:)
              end
            end
          end

          expect(task.hathi_incomplete?).to eq(true)

          HathiTrustJob.perform_now(task)

          task_records = task.holdings_records
          expect(task_records.where(ht_retrieved: true).count).to eq(record_urls_expected.size)
          expect(task_records.where(ht_retrieved: false)).not_to exist
          expect(task_records.where.not(ht_error: nil)).not_to exist

          expect(task.hathi_incomplete?).to eq(false)

          aggregate_failures do
            task_records.find_each do |ht_record|
              oclc_num = ht_record.oclc_number
              url_expected = record_urls_expected[oclc_num]
              url_actual = ht_record.ht_record_url
              expect(url_actual).to eq(url_expected), "OCLC #{oclc_num}: expected #{url_expected.inspect}, was #{url_actual.inspect}"
            end
          end
        end

        it 'handles network errors' do
          batch_uris.each_with_index do |batch_uri, i|
            batch_json_body = batch_json_bodies[i]
            if i.odd?
              stub_request(:get, batch_uri).to_return(body: batch_json_body)
            else
              stub_request(:get, batch_uri).to_return(status: 500)
            end
          end

          HathiTrustJob.perform_now(task)

          task_records = task.holdings_records
          expect(task_records.where(ht_retrieved: true).count).to eq(record_urls_expected.size)
          expect(task_records.where(ht_retrieved: false)).not_to exist

          expect(task.hathi_incomplete?).to eq(false)

          aggregate_failures do
            batches.each_with_index do |batch, i|
              batch_ht_records = task_records.where(oclc_number: batch)
              expect(batch_ht_records.count).to eq(batch.size)

              if i.odd?
                expect(batch_ht_records.where.not(ht_error: nil)).not_to exist
                batch_ht_records.find_each do |ht_record|
                  oclc_num = ht_record.oclc_number
                  url_expected = record_urls_expected[oclc_num]
                  url_actual = ht_record.ht_record_url
                  expect(url_actual).to eq(url_expected), "OCLC #{oclc_num}: expected #{url_expected.inspect}, was #{url_actual.inspect}"
                end
              else
                expect(batch_ht_records.where(ht_error: nil)).not_to exist
                expect(batch_ht_records.where.not(ht_record_url: nil)).not_to exist
                ht_errors = batch_ht_records.pluck(:ht_error)
                expect(ht_errors.uniq.size).to eq(1)
                expect(ht_errors[0]).to eq('500 Internal Server Error')
              end
            end
          end
        end

        it '"handles" being interrupted/killed and then resumed' do
          # Simulate being killed while retrieving second batch
          stub_request(:get, batch_uris[0]).to_return(body: batch_json_bodies[0])
          stub_request(:get, batch_uris[1]).to_raise(SignalException.new(:KILL))

          expect do
            HathiTrustJob.perform_now(task)
          end.to raise_error(SignalException)

          task_records = task.holdings_records
          expect(task_records.where.not(ht_error: nil)).not_to exist

          batch_ht_records = task_records.where(oclc_number: batches[0])
          expect(batch_ht_records.count).to eq(batches[0].size)
          batch_ht_records.find_each do |ht_record|
            oclc_num = ht_record.oclc_number
            url_expected = record_urls_expected[oclc_num]
            url_actual = ht_record.ht_record_url
            expect(url_actual).to eq(url_expected), "OCLC #{oclc_num}: expected #{url_expected.inspect}, was #{url_actual.inspect}"
          end

          expect(task.hathi_incomplete?).to eq(true)

          # Simulate retry after interrupt
          [1, 2].each do |i|
            stub_request(:get, batch_uris[i]).to_return(body: batch_json_bodies[i])
          end

          HathiTrustJob.perform_now(task)

          expect(task_records.where(ht_record_url: nil)).not_to exist
          expect(task_records.where.not(ht_error: nil)).not_to exist

          expect(task.hathi_incomplete?).to eq(false)

          [1, 2].each do |i|
            batch_ht_records = task_records.where(oclc_number: batches[i])
            expect(batch_ht_records.count).to eq(batches[i].size)
            batch_ht_records.find_each do |ht_record|
              oclc_num = ht_record.oclc_number
              url_expected = record_urls_expected[oclc_num]
              url_actual = ht_record.ht_record_url
              expect(url_actual).to eq(url_expected), "OCLC #{oclc_num}: expected #{url_expected.inspect}, was #{url_actual.inspect}"
            end
          end
        end
      end
    end
  end
end
