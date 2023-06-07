require 'rails_helper'
require 'support/holdings_contexts'

module Holdings
  describe WorldCatJob, type: :job do
    include_context('HoldingsRequest')

    describe :perform do
      it 'rejects a non-Worldcat request' do
        req.update(rlf: false, uc: false)

        expect { WorldCatJob.perform_now(req) }.to raise_error(ArgumentError)
      end

      it 'retrieves the holdings' do
        request_records = req.holdings_records

        oclc_numbers_expected.each do |oclc_number|
          stub_wc_request_for(oclc_number)
        end

        WorldCatJob.perform_now(req)

        expected_count = holdings_by_oclc_num.size
        expect(request_records.where(wc_retrieved: true).count).to eq(expected_count)
        expect(request_records.where(wc_retrieved: false)).not_to exist

        expect(req.wc_incomplete?).to eq(false)

        request_records.find_each do |record|
          verify_wc_symbols(record)
        end
      end

      it 'completes partially-completed jobs' do
        request_records = req.holdings_records

        # Simulate previously-completed partial job
        oclc_numbers_expected.each_with_index do |oclc_number, i|
          if i.odd?
            stub_wc_request_for(oclc_number)
          else
            symbols_expected = holdings_by_oclc_num[oclc_number]
            wc_record = request_records.find_by!(oclc_number:)
            wc_record.update(wc_retrieved: true, wc_symbols: symbols_expected.join(','))
          end
        end

        expect(req.wc_incomplete?).to eq(true)

        WorldCatJob.perform_now(req)

        expected_count = holdings_by_oclc_num.size
        expect(request_records.where(wc_retrieved: true).count).to eq(expected_count)
        expect(request_records.where(wc_retrieved: false)).not_to exist

        expect(req.wc_incomplete?).to eq(false)

        request_records.find_each do |record|
          verify_wc_symbols(record)
        end
      end

      it 'handles network errors' do
        request_records = req.holdings_records

        oclc_numbers_expected.each_with_index do |oclc_number, i|
          if i.odd?
            stub_wc_request_for(oclc_number)
          else
            req = BerkeleyLibrary::Location::WorldCat::LibrariesRequest.new(oclc_number)
            stub_request(:get, req.uri).with(query: req.params).to_return(status: 500)
          end
        end

        WorldCatJob.perform_now(req)

        expect(req.wc_incomplete?).to eq(false)

        expected_count = holdings_by_oclc_num.size
        expect(request_records.where(wc_retrieved: true).count).to eq(expected_count)
        expect(request_records.where(wc_retrieved: false)).not_to exist

        oclc_numbers_expected.each_with_index do |oclc_number, i|
          record = request_records.find_by!(oclc_number:)
          if i.odd?
            verify_wc_symbols(record)
          else
            expect(record.wc_symbols).to be_nil
            expect(record.wc_error).to eq('500 Internal Server Error')
          end
        end
      end

      it '"handles" being interrupted/killed and then resumed' do
        midpoint = oclc_numbers_expected.size / 2
        first_batch = oclc_numbers_expected[0...midpoint]
        second_batch = oclc_numbers_expected[midpoint..]

        # Simulate being killed after retrieving half the items
        first_batch.each do |oclc_number|
          stub_wc_request_for(oclc_number)
        end

        oclc_number_midpoint = oclc_numbers_expected[midpoint]
        req_midpoint = BerkeleyLibrary::Location::WorldCat::LibrariesRequest.new(oclc_number_midpoint)
        stub_request(:get, req_midpoint.uri).with(query: req_midpoint.params).to_raise(SignalException.new(:KILL))

        expect do
          WorldCatJob.perform_now(req)
        end.to raise_error(SignalException)

        request_records = req.holdings_records
        expect(request_records.where(wc_retrieved: true).count).to eq(first_batch.size)
        expect(request_records.where.not(wc_error: nil)).not_to exist

        expect(req.wc_incomplete?).to eq(true)

        # Simulate retry after interrupt
        second_batch.each do |oclc_number|
          stub_wc_request_for(oclc_number)
        end

        WorldCatJob.perform_now(req)

        expected_count = holdings_by_oclc_num.size
        expect(request_records.where(wc_retrieved: true).count).to eq(expected_count)
        expect(request_records.where(wc_retrieved: false)).not_to exist

        expect(req.wc_incomplete?).to eq(false)

        request_records.find_each(&method(:verify_wc_symbols))
      end
    end
  end
end
