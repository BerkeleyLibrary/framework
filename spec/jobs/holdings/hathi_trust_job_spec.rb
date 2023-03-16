require 'rails_helper'
require 'uploaded_file_helper'

module Holdings
  describe HathiTrustJob, type: :job do
    include UploadedFileHelper

    before do
      # ActiveStorage uses a background job to remove files
      @queue_adapter = ActiveStorage::PurgeJob.queue_adapter
      ActiveStorage::PurgeJob.queue_adapter = :inline
    end

    after do
      # Explicitly purge ActiveStorage files
      HoldingsTask.destroy_all
      ActiveStorage::Blob.unattached.find_each(&:purge_later)
      ActiveStorage::PurgeJob.queue_adapter = @queue_adapter
    end

    describe 'success' do
      let(:input_file_path) { 'spec/data/holdings/input-file.xlsx' }
      let(:oclc_numbers_expected) { File.readlines('spec/data/holdings/oclc_numbers_expected.txt', chomp: true) }
      let(:batch_size) { BerkeleyLibrary::Holdings::HathiTrust::RecordUrlBatchRequest::MAX_BATCH_SIZE }
      let(:record_urls_expected) do
        {
          '1097551039' => 'https://catalog.hathitrust.org/Record/102799570',
          '1057635605' => 'https://catalog.hathitrust.org/Record/102799038',
          '744914764' => 'https://catalog.hathitrust.org/Record/102799171',
          '841051175' => 'https://catalog.hathitrust.org/Record/102798602',
          '553365107' => 'https://catalog.hathitrust.org/Record/009544358',
          '916723577' => 'https://catalog.hathitrust.org/Record/102797247',
          '50478533' => 'https://catalog.hathitrust.org/Record/004310786',
          '1037810804' => 'https://catalog.hathitrust.org/Record/102802328',
          '1106476939' => 'https://catalog.hathitrust.org/Record/102859665',
          '1019839414' => 'https://catalog.hathitrust.org/Record/102802377',
          '1202732743' => 'https://catalog.hathitrust.org/Record/102862428',
          '1232187285' => 'https://catalog.hathitrust.org/Record/102802512',
          '43310158' => 'https://catalog.hathitrust.org/Record/102822817',
          '786872103' => 'https://catalog.hathitrust.org/Record/102799040',
          '17401297' => 'https://catalog.hathitrust.org/Record/000883404',
          '39281966' => 'https://catalog.hathitrust.org/Record/003816675',
          '1088664799' => 'https://catalog.hathitrust.org/Record/102802305',
          '959808903' => 'https://catalog.hathitrust.org/Record/102798676',
          '1183717747' => 'https://catalog.hathitrust.org/Record/102862558',
          '840927703' => 'https://catalog.hathitrust.org/Record/102801650',
          '52559229' => 'https://catalog.hathitrust.org/Record/004355036',
          '1085156076' => 'https://catalog.hathitrust.org/Record/102802433',
          '1029560997' => 'https://catalog.hathitrust.org/Record/102797429',
          '942045029' => 'https://catalog.hathitrust.org/Record/102859735',
          '42780471' => 'https://catalog.hathitrust.org/Record/004134120',
          '1052450975' => 'https://catalog.hathitrust.org/Record/102805804',
          '992798630' => 'https://catalog.hathitrust.org/Record/102802179',
          '1243000176' => 'https://catalog.hathitrust.org/Record/102862468',
          '1003209782' => 'https://catalog.hathitrust.org/Record/102862406',
          '61332593' => 'https://catalog.hathitrust.org/Record/102799571',
          '34150960' => 'https://catalog.hathitrust.org/Record/003966672',
          '1081297655' => 'https://catalog.hathitrust.org/Record/102798906',
          '268789401' => 'https://catalog.hathitrust.org/Record/011248535',
          '1083300787' => 'https://catalog.hathitrust.org/Record/102798804',
          '895650546' => 'https://catalog.hathitrust.org/Record/102859604',
          '43903564' => 'https://catalog.hathitrust.org/Record/004136040',
          '52937386' => 'https://catalog.hathitrust.org/Record/004363197',
          '43845565' => 'https://catalog.hathitrust.org/Record/004135486',
          '169455558' => 'https://catalog.hathitrust.org/Record/005678848',
          '959373652' => 'https://catalog.hathitrust.org/Record/102797428',
          '916140635' => 'https://catalog.hathitrust.org/Record/102801980',
          '779577263' => 'https://catalog.hathitrust.org/Record/102801823',
          '41531832' => 'https://catalog.hathitrust.org/Record/004054696',
          '1233025104' => 'https://catalog.hathitrust.org/Record/102862415'
        }
      end

      let(:batches) { oclc_numbers_expected.each_slice(batch_size).to_a }
      let(:batch_uris) { batches.map { |batch| BerkeleyLibrary::Holdings::HathiTrust::RecordUrlBatchRequest.new(batch).uri } }
      let(:batch_json_bodies) { Array.new(batches.size) { |i| File.read("spec/data/holdings/ht-batch-#{i}.json") } }

      attr_reader :task

      before do
        @ht_queue_adapter = HathiTrustJob.queue_adapter
        HathiTrustJob.queue_adapter = :inline

        @task = HoldingsTask.create(
          email: 'dmoles@berkeley.edu',
          filename: 'input-file.xlsx',
          hathi: true,
          input_file: uploaded_file_from(input_file_path)
        )
        task.ensure_holdings_records!
      end

      after do
        HathiTrustJob.queue_adapter = @ht_queue_adapter
      end

      describe :perform do
        it 'retrieves record URLs' do

          batch_uris.each_with_index do |batch_uri, i|
            batch_json_body = batch_json_bodies[i]
            stub_request(:get, batch_uri).to_return(body: batch_json_body)
          end

          HathiTrustJob.perform_now(task)

          task_ht_records = task.holdings_hathi_trust_records
          expect(task_ht_records.where(retrieved: true).count).to eq(record_urls_expected.size)
          expect(task_ht_records.where(retrieved: false)).not_to exist
          expect(task_ht_records.where.not(ht_error: nil)).not_to exist

          aggregate_failures do
            task_ht_records.find_each do |ht_record|
              oclc_num = ht_record.oclc_number
              url_expected = record_urls_expected[oclc_num]
              url_actual = ht_record.ht_record_url
              expect(url_actual).to eq(url_expected), "OCLC #{oclc_num}: expected #{url_expected.inspect}, was #{url_actual.inspect}"
            end
          end
        end

        it 'completes partially-completed jobs' do
          task_ht_records = task.holdings_hathi_trust_records

          batch_uris.each_with_index do |batch_uri, i|
            batch_json_body = batch_json_bodies[i]
            if i.odd?
              stub_request(:get, batch_uri).to_return(body: batch_json_body)
            else
              # Simulate previously-completed partial job
              batches[i].each do |oclc_number|
                ht_record_url = record_urls_expected[oclc_number]
                record = task_ht_records.find_by!(oclc_number:)
                record.update(retrieved: true, ht_record_url:)
              end
            end
          end

          HathiTrustJob.perform_now(task)

          task_ht_records = task.holdings_hathi_trust_records
          expect(task_ht_records.where(retrieved: true).count).to eq(record_urls_expected.size)
          expect(task_ht_records.where(retrieved: false)).not_to exist
          expect(task_ht_records.where.not(ht_error: nil)).not_to exist

          aggregate_failures do
            task_ht_records.find_each do |ht_record|
              oclc_num = ht_record.oclc_number
              url_expected = record_urls_expected[oclc_num]
              url_actual = ht_record.ht_record_url
              expect(url_actual).to eq(url_expected), "OCLC #{oclc_num}: expected #{url_expected.inspect}, was #{url_actual.inspect}"
            end
          end
        end

        it 'handles errors' do
          batch_uris.each_with_index do |batch_uri, i|
            batch_json_body = batch_json_bodies[i]
            if i.odd?
              stub_request(:get, batch_uri).to_return(body: batch_json_body)
            else
              stub_request(:get, batch_uri).to_return(status: 404)
            end
          end

          HathiTrustJob.perform_now(task)

          task_ht_records = task.holdings_hathi_trust_records
          expect(task_ht_records.where(retrieved: true).count).to eq(record_urls_expected.size)
          expect(task_ht_records.where(retrieved: false)).not_to exist

          aggregate_failures do
            batches.each_with_index do |batch, i|
              batch_ht_records = task_ht_records.where(oclc_number: batch)
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
                expect(ht_errors[0]).to eq('404 Not Found')
              end
            end
          end
        end
      end
    end
  end
end
