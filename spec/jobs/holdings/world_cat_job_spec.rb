require 'rails_helper'
require 'support/holdings_contexts'

module Holdings
  describe WorldCatJob, type: :job do
    include_context('HoldingsTask')

    def stub_request_for(oclc_number)
      req = BerkeleyLibrary::Holdings::WorldCat::LibrariesRequest.new(oclc_number)
      xml = File.read("spec/data/holdings/world_cat/#{oclc_number}.xml")
      stub_request(:get, req.uri).with(query: req.params).to_return(body: xml)
    end

    describe :perform do
      it 'rejects a non-Worldcat task' do
        task.update(rlf: false, uc: false)

        expect { WorldCatJob.perform_now(task) }.to raise_error(ArgumentError)
      end

      it 'retrieves the holdings' do
        task_records = task.holdings_records

        oclc_numbers_expected.each do |oclc_number|
          stub_request_for(oclc_number)
        end

        WorldCatJob.perform_now(task)

        expected_count = holdings_by_oclc_num.size
        expect(task_records.where(wc_retrieved: true).count).to eq(expected_count)
        expect(task_records.where(wc_retrieved: false)).not_to exist

        expect(task.wc_incomplete?).to eq(false)

        task_records.find_each do |wc_record|
          oclc_number = wc_record.oclc_number
          symbols_expected = holdings_by_oclc_num[oclc_number]
          symbols_actual = wc_record.wc_symbols.split(',')
          expect(symbols_actual).to contain_exactly(*symbols_expected)
        end
      end

      it 'completes partially-completed jobs' do
        task_records = task.holdings_records

        # Simulate previously-completed partial job
        oclc_numbers_expected.each_with_index do |oclc_number, i|
          if i.odd?
            stub_request_for(oclc_number)
          else
            symbols_expected = holdings_by_oclc_num[oclc_number]
            wc_record = task_records.find_by!(oclc_number:)
            wc_record.update(wc_retrieved: true, wc_symbols: symbols_expected.join(','))
          end
        end

        expect(task.wc_incomplete?).to eq(true)

        WorldCatJob.perform_now(task)

        expected_count = holdings_by_oclc_num.size
        expect(task_records.where(wc_retrieved: true).count).to eq(expected_count)
        expect(task_records.where(wc_retrieved: false)).not_to exist

        expect(task.wc_incomplete?).to eq(false)

        task_records.find_each do |wc_record|
          oclc_number = wc_record.oclc_number
          symbols_expected = holdings_by_oclc_num[oclc_number]
          symbols_actual = wc_record.wc_symbols.split(',')
          expect(symbols_actual).to contain_exactly(*symbols_expected)
        end
      end

      it 'handles network errors' do
        task_records = task.holdings_records

        oclc_numbers_expected.each_with_index do |oclc_number, i|
          if i.odd?
            stub_request_for(oclc_number)
          else
            req = BerkeleyLibrary::Holdings::WorldCat::LibrariesRequest.new(oclc_number)
            stub_request(:get, req.uri).with(query: req.params).to_return(status: 500)
          end
        end

        WorldCatJob.perform_now(task)

        expect(task.wc_incomplete?).to eq(false)

        expected_count = holdings_by_oclc_num.size
        expect(task_records.where(wc_retrieved: true).count).to eq(expected_count)
        expect(task_records.where(wc_retrieved: false)).not_to exist

        oclc_numbers_expected.each_with_index do |oclc_number, i|
          wc_record = task_records.find_by!(oclc_number:)
          if i.odd?
            symbols_expected = holdings_by_oclc_num[oclc_number]
            symbols_actual = wc_record.wc_symbols.split(',')
            expect(symbols_actual).to contain_exactly(*symbols_expected)
            expect(wc_record.wc_error).to be_nil
          else
            expect(wc_record.wc_symbols).to be_nil
            expect(wc_record.wc_error).to eq('500 Internal Server Error')
          end
        end
      end

      it '"handles" being interrupted/killed and then resumed' do
        midpoint = oclc_numbers_expected.size / 2
        first_batch = oclc_numbers_expected[0...midpoint]
        second_batch = oclc_numbers_expected[midpoint..]

        # Simulate being killed after retrieving half the items
        first_batch.each do |oclc_number|
          stub_request_for(oclc_number)
        end

        oclc_number_midpoint = oclc_numbers_expected[midpoint]
        req_midpoint = BerkeleyLibrary::Holdings::WorldCat::LibrariesRequest.new(oclc_number_midpoint)
        stub_request(:get, req_midpoint.uri).with(query: req_midpoint.params).to_raise(SignalException.new(:KILL))

        expect do
          WorldCatJob.perform_now(task)
        end.to raise_error(SignalException)

        task_records = task.holdings_records
        expect(task_records.where(wc_retrieved: true).count).to eq(first_batch.size)
        expect(task_records.where.not(wc_error: nil)).not_to exist

        expect(task.wc_incomplete?).to eq(true)

        # Simulate retry after interrupt
        second_batch.each do |oclc_number|
          stub_request_for(oclc_number)
        end

        WorldCatJob.perform_now(task)

        expected_count = holdings_by_oclc_num.size
        expect(task_records.where(wc_retrieved: true).count).to eq(expected_count)
        expect(task_records.where(wc_retrieved: false)).not_to exist

        expect(task.wc_incomplete?).to eq(false)

        task_records.find_each do |wc_record|
          oclc_number = wc_record.oclc_number
          symbols_expected = holdings_by_oclc_num[oclc_number]
          symbols_actual = wc_record.wc_symbols.split(',')
          expect(symbols_actual).to contain_exactly(*symbols_expected)
        end
      end
    end
  end
end
