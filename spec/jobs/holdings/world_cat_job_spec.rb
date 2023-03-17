require 'rails_helper'
require 'support/holdings_task_context'

module Holdings
  describe WorldCatJob, type: :job do
    include_context('HoldingsTask')

    let(:holdings_by_oclc_num) do
      {
        '1097551039' => %w[CUV CUY],
        '1057635605' => %w[CUV CUY],
        '744914764' => %w[CLU CUS CUV CUY MERUC],
        '841051175' => %w[CRU CUI CUN CUS CUT CUV CUY CUZ],
        '553365107' => %w[CLU CRU CUI CUS CUV CUY CUZ MERUC ZAS],
        '916723577' => %w[CLU CUI CUS CUY],
        '50478533' => %w[CUS CUV CUY],
        '1037810804' => %w[CLU CRU CUI CUS CUV CUY CUZ MERUC],
        '1106476939' => %w[CUI CUV CUY CUZ],
        '1019839414' => ['CUY'],
        '1202732743' => %w[CLU CUY],
        '1232187285' => ['CUY'],
        '43310158' => %w[CUI CUY],
        '786872103' => ['CUY'],
        '17401297' => %w[CLU CRU CUI CUS CUT CUV CUY CUZ ZAS],
        '39281966' => %w[CLU CRU CUI CUS CUY ZAP],
        '1088664799' => ['CUY'],
        '959808903' => %w[CLU CRU CUI CUS CUT CUV CUY CUZ MERUC],
        '1183717747' => %w[CLU CUY],
        '840927703' => %w[CRU CUI CUS CUT CUV CUY CUZ],
        '52559229' => %w[CLU CRU CUI CUS CUT CUV CUY CUZ],
        '1085156076' => ['CUY'],
        '1029560997' => %w[CUI CUY],
        '942045029' => %w[CRU CUT CUY],
        '42780471' => %w[CLU CUI CUS CUT CUV CUY ZAS],
        '1052450975' => %w[CLU CRU CUI CUS CUT CUV CUY CUZ MERUC],
        '992798630' => %w[CLU CRU CUY],
        '1243000176' => %w[CLU CRU CUV CUY],
        '1003209782' => ['CUY'],
        '61332593' => %w[CLU CRU CUS CUT CUV CUY CUZ MERUC],
        '34150960' => %w[CLU CRU CUS CUV CUY CUZ MERUC],
        '1081297655' => [],
        '268789401' => %w[CUS CUV CUY CUZ],
        '1083300787' => ['CUY'],
        '895650546' => %w[CUI CUT CUY],
        '43903564' => %w[CLU CRU CUI CUT CUV CUY ZAP],
        '52937386' => %w[CLU CRU CUI CUS CUT CUV CUY CUZ MERUC ZAP],
        '43845565' => %w[CLU CRU CUI CUS CUT CUV CUY CUZ MERUC],
        '169455558' => %w[CLU CRU CUI CUV CUY],
        '959373652' => %w[CUI CUS CUV CUY],
        '916140635' => ['CUY'],
        '779577263' => %w[CLU CRU CUI CUN CUS CUV CUY CUZ],
        '41531832' => %w[CLU CRU CUT CUV CUY CUZ],
        '1233025104' => ['CUY']
      }
    end

    it 'retrieves the holdings' do
      task_wc_records = task.holdings_world_cat_records

      oclc_numbers_expected.each do |oclc_number|
        req = BerkeleyLibrary::Holdings::WorldCat::LibrariesRequest.new(oclc_number)
        xml = File.read("spec/data/holdings/world_cat/#{oclc_number}.xml")
        stub_request(:get, req.uri).with(query: req.params).to_return(body: xml)
      end

      WorldCatJob.perform_now(task)

      expected_count = holdings_by_oclc_num.size
      expect(task_wc_records.where(retrieved: true).count).to eq(expected_count)
      expect(task_wc_records.where(retrieved: false)).not_to exist

      task_wc_records.find_each do |wc_record|
        oclc_number = wc_record.oclc_number
        symbols_expected = holdings_by_oclc_num[oclc_number]
        symbols_actual = wc_record.wc_symbols.split(',')
        expect(symbols_actual).to contain_exactly(*symbols_expected)
      end
    end

    it 'completes partially-completed jobs' do
      task_wc_records = task.holdings_world_cat_records

      oclc_numbers_expected.each_with_index do |oclc_number, i|
        if i.odd?
          req = BerkeleyLibrary::Holdings::WorldCat::LibrariesRequest.new(oclc_number)
          xml = File.read("spec/data/holdings/world_cat/#{oclc_number}.xml")
          stub_request(:get, req.uri).with(query: req.params).to_return(body: xml)
        else
          symbols_expected = holdings_by_oclc_num[oclc_number]
          wc_record = task_wc_records.find_by!(oclc_number:)
          wc_record.update(retrieved: true, wc_symbols: symbols_expected.join(','))
        end
      end

      WorldCatJob.perform_now(task)

      expected_count = holdings_by_oclc_num.size
      expect(task_wc_records.where(retrieved: true).count).to eq(expected_count)
      expect(task_wc_records.where(retrieved: false)).not_to exist

      task_wc_records.find_each do |wc_record|
        oclc_number = wc_record.oclc_number
        symbols_expected = holdings_by_oclc_num[oclc_number]
        symbols_actual = wc_record.wc_symbols.split(',')
        expect(symbols_actual).to contain_exactly(*symbols_expected)
      end
    end

    it 'handles network errors' do
      task_wc_records = task.holdings_world_cat_records

      oclc_numbers_expected.each_with_index do |oclc_number, i|
        req = BerkeleyLibrary::Holdings::WorldCat::LibrariesRequest.new(oclc_number)
        if i.odd?
          xml = File.read("spec/data/holdings/world_cat/#{oclc_number}.xml")
          stub_request(:get, req.uri).with(query: req.params).to_return(body: xml)
        else
          stub_request(:get, req.uri).with(query: req.params).to_return(status: 500)
        end
      end

      WorldCatJob.perform_now(task)

      expected_count = holdings_by_oclc_num.size
      expect(task_wc_records.where(retrieved: true).count).to eq(expected_count)
      expect(task_wc_records.where(retrieved: false)).not_to exist

      oclc_numbers_expected.each_with_index do |oclc_number, i|
        wc_record = task_wc_records.find_by!(oclc_number:)
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
  end
end
