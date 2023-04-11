require 'support/uploaded_file_context'

RSpec.shared_context('holdings data') do
  let(:oclc_numbers_expected) { File.readlines('spec/data/holdings/oclc_numbers_expected.txt', chomp: true) }
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
end

RSpec.shared_context('purge HoldingsTasks') do
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
end

RSpec.shared_context('HoldingsTask') do
  include_context 'uploaded file'
  include_context 'holdings data'
  include_context 'purge HoldingsTasks'

  let(:batch_size) { BerkeleyLibrary::Holdings::HathiTrust::RecordUrlBatchRequest::MAX_BATCH_SIZE }

  let(:batches) { oclc_numbers_expected.each_slice(batch_size).to_a }
  let(:ht_batch_uris) { batches.map { |batch| BerkeleyLibrary::Holdings::HathiTrust::RecordUrlBatchRequest.new(batch).uri } }
  let(:ht_batch_json_bodies) { Array.new(batches.size) { |i| File.read("spec/data/holdings/hathi_trust/ht-batch-#{i}.json") } }

  def stub_wc_request_for(oclc_number)
    req = BerkeleyLibrary::Holdings::WorldCat::LibrariesRequest.new(oclc_number)
    xml = File.read("spec/data/holdings/world_cat/#{oclc_number}.xml")
    stub_request(:get, req.uri).with(query: req.params).to_return(body: xml)
  end

  def stub_ht_request(ht_batch_uri)
    index = ht_batch_uris.index(ht_batch_uri)
    batch_json_body = ht_batch_json_bodies[index]
    stub_request(:get, ht_batch_uri).to_return(body: batch_json_body)
  end

  def verify_ht_record_url(record)
    expect(record.ht_error).to be_nil
    expect(record.ht_retrieved).to eq(true)

    oclc_number = record.oclc_number
    url_expected = record_urls_expected[oclc_number]
    url_actual = record.ht_record_url
    expect(url_actual).to eq(url_expected), "OCLC #{oclc_number}: expected #{url_expected.inspect}, was #{url_actual.inspect}"
  end

  def verify_wc_symbols(record)
    expect(record.wc_error).to be_nil
    expect(record.wc_retrieved).to eq(true)

    oclc_number = record.oclc_number
    symbols_expected = holdings_by_oclc_num[oclc_number]
    symbols_actual = record.wc_symbols.split(',')
    expect(symbols_actual).to contain_exactly(*symbols_expected)
  end

  let(:input_file_path) { 'spec/data/holdings/input-file.xlsx' }

  attr_reader :task

  before do
    @task = HoldingsTask.create(
      email: 'dmoles@berkeley.edu',
      filename: 'input-file.xlsx',
      hathi: true,
      rlf: true,
      uc: true,
      input_file: uploaded_file_from(input_file_path)
    )
    task.ensure_holdings_records!
  end
end

RSpec.shared_context('complete HoldingsTask') do
  include_context('HoldingsTask')

  before do
    ht_retrieved = true
    wc_retrieved = true
    task.holdings_records.find_each do |rec|
      oclc_number = rec.oclc_number
      wc_symbols = holdings_by_oclc_num[oclc_number].join(',')
      ht_record_url = record_urls_expected[oclc_number]
      rec.update(wc_symbols:, wc_retrieved:, ht_record_url:, ht_retrieved:)
    end
    expect(task).not_to be_incomplete # just to be sure
  end

  def assert_complete!(ss)
    cnames = ['OCLC Number', 'NRLF', 'SRLF', 'Other UC', 'Hathi Trust']
    c_oclc, c_nrlf, c_srlf, c_uc, c_ht = cnames.map do |cname|
      ss.find_column_index_by_header!(cname)
    end

    oclc_numbers_expected.each_with_index do |oclc_number, i|
      r_index = i + 1 # skip header

      wc_symbols = holdings_by_oclc_num[oclc_number]
      has_nrlf = wc_symbols.intersection(BerkeleyLibrary::Holdings::WorldCat::Symbols::NRLF).any?
      has_srlf = wc_symbols.intersection(BerkeleyLibrary::Holdings::WorldCat::Symbols::SRLF).any?
      expected_uc = wc_symbols.intersection(BerkeleyLibrary::Holdings::WorldCat::Symbols::UC)

      ht_record_url = record_urls_expected[oclc_number]

      expected_values = {
        c_oclc => oclc_number.to_i, # source data is numeric
        c_nrlf => ('nrlf' if has_nrlf),
        c_srlf => ('srlf' if has_srlf),
        c_uc => (expected_uc.join(',') if expected_uc.any?),
        c_ht => ht_record_url
      }

      expected_values.each do |c_index, v_expected|
        v_actual = ss.value_at(r_index, c_index)
        expect(v_actual).to eq(v_expected), "(#{r_index}, #{c_index}): expected #{v_expected.inspect}, was #{v_actual.inspect}"
      end
    end
  end

  def assert_output_complete!(task)
    expect(task.output_file).to be_attached

    ss = task.output_file.open do |tmpfile|
      BerkeleyLibrary::Util::XLSX::Spreadsheet.new(tmpfile.path)
    end

    assert_complete!(ss)
  end
end

RSpec.shared_context('incomplete HoldingsTask') do
  include_context('HoldingsTask')

  before do
    task.holdings_records.find_each.with_index do |rec, i|
      oclc_number = rec.oclc_number

      options = {}.tap do |opts|
        if i.even?
          opts[:wc_retrieved] = true
          opts[:wc_symbols] = holdings_by_oclc_num[oclc_number].join(',')
        end

        if i % 3 == 0
          opts[:ht_retrieved] = true
          opts[:ht_record_url] = record_urls_expected[oclc_number]
        end
      end

      rec.update(**options) unless options.empty?
    end
    expect(task).to be_incomplete # just to be sure
  end
end

RSpec.shared_context('incomplete HoldingsTask with errors') do
  include_context('incomplete HoldingsTask')

  before do
    task.holdings_records.where(wc_retrieved: true).find_each.with_index do |rec, i|
      rec.update(wc_symbols: nil, wc_error: '403 Forbidden') if i.even?
    end

    task.holdings_records.where(ht_retrieved: true).find_each.with_index do |rec, i|
      rec.update(ht_record_url: nil, ht_error: '500 Internal Server Error') if i % 3 == 0
    end
  end
end

RSpec.shared_context('complete HoldingsTask with errors') do
  include_context('complete HoldingsTask')

  before do
    task.holdings_records.find_each.with_index do |r, i|
      r.update(wc_symbols: nil, wc_error: '403 Forbidden') if i.even?
      r.update(ht_record_url: nil, ht_error: '500 Internal Server Error') if i % 3 == 0
    end
  end
end
