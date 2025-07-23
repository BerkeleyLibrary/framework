require 'rails_helper'
require 'support/location_contexts'

module Location
  describe HathiTrustJob, type: :job do
    include_context('LocationRequest')

    describe 'success' do

      describe :perform do
        it 'rejects a non-HathiTrust request' do
          req.update(hathi: false)

          expect { HathiTrustJob.perform_now(req) }.to raise_error(ArgumentError)
        end

        it 'retrieves record URLs' do

          ht_batch_uris.each { |batch_uri| stub_ht_request(batch_uri) }

          HathiTrustJob.perform_now(req)

          request_records = req.location_records
          expected_count = record_urls_expected.size
          expect(request_records.where(ht_retrieved: true).count).to eq(expected_count)
          expect(request_records.where(ht_retrieved: false)).not_to exist
          expect(request_records.where.not(ht_error: nil)).not_to exist

          expect(req.hathi_incomplete?).to eq(false)

          aggregate_failures do
            request_records.find_each(&method(:verify_ht_record_url))
          end
        end

        # rubocop:disable RSpec/ExampleLength
        it 'completes partially-completed jobs' do
          request_records = req.location_records

          ht_batch_uris.each_with_index do |batch_uri, i|
            if i.odd?
              stub_ht_request(batch_uri)
            else
              # Simulate previously-completed partial job
              batches[i].each do |oclc_number|
                ht_record_url = record_urls_expected[oclc_number]
                record = request_records.find_by!(oclc_number:)
                record.update(ht_retrieved: true, ht_record_url:)
              end
            end
          end

          expect(req.hathi_incomplete?).to eq(true)

          HathiTrustJob.perform_now(req)

          request_records = req.location_records
          expect(request_records.where(ht_retrieved: true).count).to eq(record_urls_expected.size)
          expect(request_records.where(ht_retrieved: false)).not_to exist
          expect(request_records.where.not(ht_error: nil)).not_to exist

          expect(req.hathi_incomplete?).to eq(false)

          aggregate_failures do
            request_records.find_each do |record|
              verify_ht_record_url(record)
            end
          end
        end

        it 'handles network errors' do
          ht_batch_uris.each_with_index do |batch_uri, i|
            if i.odd?
              stub_ht_request(batch_uri)
            else
              stub_request(:get, batch_uri).to_return(status: 500)
            end
          end

          HathiTrustJob.perform_now(req)

          request_records = req.location_records
          expect(request_records.where(ht_retrieved: true).count).to eq(record_urls_expected.size)
          expect(request_records.where(ht_retrieved: false)).not_to exist

          expect(req.hathi_incomplete?).to eq(false)

          aggregate_failures do
            batches.each_with_index do |batch, i|
              batch_ht_records = request_records.where(oclc_number: batch)
              expect(batch_ht_records.count).to eq(batch.size)

              if i.odd?
                expect(batch_ht_records.where.not(ht_error: nil)).not_to exist
                batch_ht_records.find_each do |record|
                  verify_ht_record_url(record)
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
          stub_request(:get, ht_batch_uris[0]).to_return(body: ht_batch_json_bodies[0])
          stub_request(:get, ht_batch_uris[1]).to_raise(SignalException.new(:KILL))

          expect do
            HathiTrustJob.perform_now(req)
          end.to raise_error(SignalException)

          request_records = req.location_records
          expect(request_records.where.not(ht_error: nil)).not_to exist

          batch_ht_records = request_records.where(oclc_number: batches[0])
          expect(batch_ht_records.count).to eq(batches[0].size)
          batch_ht_records.find_each do |record|
            verify_ht_record_url(record)
          end

          expect(req.hathi_incomplete?).to eq(true)

          # Simulate retry after interrupt
          [1, 2].each do |i|
            stub_request(:get, ht_batch_uris[i]).to_return(body: ht_batch_json_bodies[i])
          end

          HathiTrustJob.perform_now(req)

          expect(request_records.where(ht_record_url: nil)).not_to exist
          expect(request_records.where.not(ht_error: nil)).not_to exist

          expect(req.hathi_incomplete?).to eq(false)

          [1, 2].each do |i|
            batch_ht_records = request_records.where(oclc_number: batches[i])
            expect(batch_ht_records.count).to eq(batches[i].size)
            batch_ht_records.find_each do |record|
              verify_ht_record_url(record)
            end
          end
        end
        # rubocop:enable RSpec/ExampleLength
      end
    end
  end
end
