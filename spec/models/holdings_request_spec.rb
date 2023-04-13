require 'rails_helper'
require 'support/uploaded_file_context'
require 'support/holdings_contexts'

RSpec.describe HoldingsRequest, type: :model do
  include_context('uploaded file')
  include_context('holdings data')
  include_context 'purge HoldingsRequests'

  # ------------------------------------------------------------
  # Fixture

  # -------------------------------
  # static inputs

  let(:input_file_path) { 'spec/data/holdings/input-file.xlsx' }
  let(:input_file_basename) { File.basename(input_file_path) }
  let(:oclc_numbers_expected) { File.readlines('spec/data/holdings/oclc_numbers_expected.txt', chomp: true) }

  # -------------------------------
  # helper methods

  def uploaded_file
    # Tempfile#path will return null if it's been unlinked (deleted)
    return @uploaded_file if @uploaded_file && @uploaded_file.path

    @uploaded_file = uploaded_file_from(input_file_path, mime_type: mime_type_xlsx)
  end

  def assert_same_contents(expected_path, actual_attachment)
    expected_blob = File.binread(expected_path)
    expect(actual_attachment).to be_attached
    expect(actual_attachment.filename).to eq(input_file_basename)
    expect(actual_attachment.content_type).to eq(mime_type_xlsx)

    actual_blob = actual_attachment.download
    expect(actual_blob).to eq(expected_blob)
  end

  # -------------------------------
  # setup / teardown

  # TODO: is it safe to use let() here?
  attr_reader :valid_attributes

  before do
    @valid_attributes = {
      email: 'me@example.test',
      filename: 'test.xlsx',
      rlf: true,
      uc: true,
      hathi: true,
      input_file: uploaded_file
    }
  end

  # ------------------------------------------------------------
  # Tests

  describe 'validation' do
    it 'accepts valid attributes' do
      req = HoldingsRequest.new(**valid_attributes)
      expect(req).to be_valid
    end

    it 'requires an email address' do
      invalid_attributes = valid_attributes.except(:email)
      req = HoldingsRequest.new(**invalid_attributes)
      expect(req).not_to be_valid
    end

    it 'requires a filename' do
      invalid_attributes = valid_attributes.except(:filename)
      req = HoldingsRequest.new(**invalid_attributes)
      expect(req).not_to be_valid
    end

    it 'requires at least one option to be set' do
      invalid_attributes = valid_attributes.except(:rlf, :uc, :hathi)
      req = HoldingsRequest.new(**invalid_attributes)
      expect(req).not_to be_valid
    end
  end

  describe :create do
    it 'accepts an input file' do
      req = HoldingsRequest.create!(**valid_attributes)
      assert_same_contents(input_file_path, req.input_file)
    end

    it 'accepts an IO' do
      attributes = valid_attributes.except(:input_file)
      attributes[:input_file] = {
        io: File.open(input_file_path),
        filename: input_file_basename,
        content_type: mime_type_xlsx
      }

      req = HoldingsRequest.create!(**attributes)
      assert_same_contents(input_file_path, req.input_file)
    end

    context 'with invalid input file' do
      let(:excel_95_path) { 'spec/data/holdings/input-file-excel95.xls' }

      attr_reader :attributes

      before do
        input_file = uploaded_file_from(excel_95_path)
        @attributes = valid_attributes.except(:input_file).merge(input_file:)
      end

      describe :create_from do
        context 'with an UploadedFile' do
          it 'marks the record invalid' do
            options = attributes.except(:filename)
            req = HoldingsRequest.create_from(**options)
            expect(req).not_to be_persisted
            expect(req.id).to be_nil

            errors = req.errors[:input_file]
            expect(errors.size).to eq(1)
            expect(errors[0]).to match(%r{application/x-ole-storage})

            expect(ActiveStorage::Blob).not_to exist
          end
        end

        context 'with an IO' do
          it 'marks the record invalid' do
            attributes = valid_attributes.except(:input_file)
            attributes[:input_file] = {
              io: File.open(excel_95_path),
              filename: input_file_basename,
              content_type: mime_type_xlsx
            }

            options = attributes.except(:filename)
            req = HoldingsRequest.create_from(**options)
            expect(req).not_to be_persisted
            expect(req.id).to be_nil

            errors = req.errors[:input_file]
            expect(errors.size).to eq(1)
            expect(errors[0]).to match(%r{application/x-ole-storage})

            expect(ActiveStorage::Blob).not_to exist
          end
        end

      end

      describe :ensure_holdings_records! do
        it 'raises ArgumentError' do
          req = HoldingsRequest.create!(**attributes)
          expect { req.ensure_holdings_records! }.to raise_error(ArgumentError)

          expect(req.holdings_records).not_to exist
        end
      end
    end
  end

  describe :create_from do
    let(:cf_attributes) { valid_attributes.except(:filename) }
    let(:numbers_expected_sorted) { oclc_numbers_expected.sort }

    context 'with an UploadedFile' do
      it 'attaches the file and creates holdings records' do
        req = HoldingsRequest.create_from(**cf_attributes)
        expect(req).to be_persisted

        input_file = req.input_file
        expect(input_file).to be_attached
        assert_same_contents(input_file_path, input_file)

        request_records = req.holdings_records
        expect(request_records.count).to eq(numbers_expected_sorted.size)

        wc_oclc_numbers = request_records.pluck(:oclc_number)
        expect(wc_oclc_numbers.sort).to eq(numbers_expected_sorted)
      end
    end

    context 'with an IO' do
      it 'attaches the file and creates holdings records' do
        cf_attributes[:input_file] = {
          io: File.open(input_file_path),
          filename: input_file_basename,
          content_type: mime_type_xlsx
        }

        req = HoldingsRequest.create_from(**cf_attributes)
        expect(req).to be_persisted

        input_file = req.input_file
        expect(input_file).to be_attached
        assert_same_contents(input_file_path, input_file)

        request_records = req.holdings_records
        expect(request_records.count).to eq(numbers_expected_sorted.size)

        wc_oclc_numbers = request_records.pluck(:oclc_number)
        expect(wc_oclc_numbers.sort).to eq(numbers_expected_sorted)
      end
    end

  end

  describe :destroy do
    it 'removes holdings records' do
      req = HoldingsRequest.create!(**valid_attributes)
      req.ensure_holdings_records!
      expect(req.holdings_records).to exist # just to be sure

      req.destroy!
      expect(req.holdings_records).not_to exist
    end

    it 'removes attached files' do
      req = HoldingsRequest.create!(
        email: 'me@example.test',
        filename: input_file_basename,
        rlf: true,
        input_file: {
          io: File.open(input_file_path),
          filename: input_file_basename,
          content_type: mime_type_xlsx
        },
        output_file: {
          io: File.open(input_file_path),
          filename: input_file_basename,
          content_type: mime_type_xlsx
        }
      )

      attachments = [req.input_file, req.output_file]
      storage_paths = attachments.map { |f| ActiveStorage::Blob.service.path_for(f.key) }

      storage_paths.each { |path| expect(File.exist?(path)).to eq(true) } # just to be sure

      req.destroy!

      storage_paths.each { |path| expect(File.exist?(path)).to eq(false) }
    end
  end

  describe :search_wc_symbols do
    it 'returns the symbols' do
      req = HoldingsRequest.create!(**valid_attributes)
      symbols_expected = BerkeleyLibrary::Holdings::WorldCat::Symbols::ALL
      expect(req.search_wc_symbols).to contain_exactly(*symbols_expected)
    end

    it 'is not affected by the presence/absence of :hathi' do
      attributes = valid_attributes.except(:hathi)
      req = HoldingsRequest.create!(**attributes)
      symbols_expected = BerkeleyLibrary::Holdings::WorldCat::Symbols::ALL
      expect(req.search_wc_symbols).to contain_exactly(*symbols_expected)
    end

    it 'returns nil for HathiTrust-only requests' do
      attributes = valid_attributes.except(:rlf, :uc)
      req = HoldingsRequest.create!(**attributes)
      expect(req.search_wc_symbols).to be_nil
    end

    it 'returns RLF symbols for RLF requests' do
      attributes = valid_attributes.except(:uc)
      req = HoldingsRequest.create!(**attributes)
      symbols_expected = BerkeleyLibrary::Holdings::WorldCat::Symbols::RLF
      expect(req.search_wc_symbols).to contain_exactly(*symbols_expected)
    end

    it 'returns UC symbols for UC requests' do
      attributes = valid_attributes.except(:rlf)
      req = HoldingsRequest.create!(**attributes)
      symbols_expected = BerkeleyLibrary::Holdings::WorldCat::Symbols::UC
      expect(req.search_wc_symbols).to contain_exactly(*symbols_expected)
    end
  end

  describe :ensure_holdings_records! do
    let(:numbers_expected_sorted) { oclc_numbers_expected.sort }

    it 'attaches holdings records' do
      req = HoldingsRequest.create!(**valid_attributes)
      req.ensure_holdings_records!

      request_records = req.holdings_records
      expect(request_records.count).to eq(numbers_expected_sorted.size)

      wc_oclc_numbers = request_records.pluck(:oclc_number)
      expect(wc_oclc_numbers.sort).to eq(numbers_expected_sorted)

      expect(request_records.where(wc_retrieved: true)).not_to exist
      expect(request_records.where(ht_retrieved: true)).not_to exist
    end

    it 'is idempotent' do
      req = HoldingsRequest.create!(**valid_attributes)
      2.times { req.ensure_holdings_records! }

      expected_count = oclc_numbers_expected.size
      expect(req.holdings_records.count).to eq(expected_count)
    end

    it 'ignores duplicate OCLC numbers' do
      attributes = valid_attributes.except(:input_file)
      attributes[:input_file] = uploaded_file_from('spec/data/holdings/input-file-duplicates.xlsx')
      req = HoldingsRequest.create!(**attributes)
      req.ensure_holdings_records!

      expected_count = oclc_numbers_expected.size
      expect(req.holdings_records.count).to eq(expected_count)
    end

    it 'handles large numbers of records' do
      # NOTE: tested with up to 1 million, but it's slow (~4 minutes)
      expected_count = 15_000
      oclc_numbers = Array.new(expected_count) { |i| (expected_count + i).to_s }
      oclc_numbers.shuffle!

      Dir.mktmpdir(File.basename(__FILE__)) do |tmpdir|
        original_path = 'spec/data/holdings/input-file-empty.xlsx'
        new_path = File.join(tmpdir, "#{expected_count}.xlsx")

        ss = BerkeleyLibrary::Util::XLSX::Spreadsheet.new(original_path)
        c_index = ss.find_column_index_by_header!(BerkeleyLibrary::Holdings::Constants::OCLC_COL_HEADER)
        oclc_numbers.each_with_index do |oclc_num, i|
          r_index = 1 + i # skip header row
          ss.set_value_at(r_index, c_index, oclc_num)
        end
        ss.save_as(new_path)

        input_file = uploaded_file_from(new_path, mime_type: mime_type_xlsx)

        attributes = valid_attributes.except(:input_file)
        attributes[:input_file] = input_file

        req = HoldingsRequest.create!(**attributes)
        req.ensure_holdings_records!

        expect(req.holdings_records.count).to eq(expected_count)
      end
    end
  end

  describe :with_input_tmpfile do
    context 'with attachment uploaded' do
      it 'yields a temporary file containing the input data' do
        expected_blob = File.binread(input_file_path)
        req = HoldingsRequest.create!(**valid_attributes)

        actual_blob = req.with_input_tmpfile { |tmpfile| File.binread(tmpfile.path) }
        expect(actual_blob).to eq(expected_blob)
      end
    end

    context 'before attachment uploaded' do
      it 'yields a temporary file containing the input data' do
        expected_blob = File.binread(input_file_path)
        HoldingsRequest.transaction do
          req = HoldingsRequest.create(**valid_attributes)
          actual_blob = req.with_input_tmpfile { |tmpfile| File.binread(tmpfile.path) }
          expect(actual_blob).to eq(expected_blob)
        end
      end
    end
  end

  describe :each_input_oclc do
    attr_reader :req

    context 'success' do
      before do
        @req = HoldingsRequest.create!(**valid_attributes)
      end

      it 'returns an enum' do
        en = req.each_input_oclc
        expect(en).to be_an(Enumerator)
        expect(en.to_a).to eq(oclc_numbers_expected)
      end

      it 'yields each OCLC number' do
        expect { |b| req.each_input_oclc(&b) }
          .to yield_successive_args(*oclc_numbers_expected)
      end
    end

    context 'failure' do
      it 'returns an empty enum for an empty input file' do
        input_file = uploaded_file_from('spec/data/holdings/input-file-empty.xlsx')
        attributes = valid_attributes.except(:input_file)
        attributes[:input_file] = input_file

        req = HoldingsRequest.create!(**attributes)
        expect(req.each_input_oclc.to_a).to eq([])
      end
    end
  end

  describe :ensure_output_file! do
    include_context 'complete HoldingsRequest'

    it 'writes the output file' do
      req.ensure_output_file!

      expect(req.output_file).to be_attached

      ss = req.output_file.open do |tmpfile|
        BerkeleyLibrary::Util::XLSX::Spreadsheet.new(tmpfile.path)
      end

      assert_complete!(ss)
    end

    context 'with existing output' do
      before do
        req.send(:write_output_file!)
      end

      it 'does not re-create an existing output file' do
        expect(BerkeleyLibrary::Holdings::XLSXWriter).not_to receive(:new)

        req.ensure_output_file!
        assert_output_complete!(req)
      end
    end
  end

  describe :completed_count do
    shared_examples 'counting completed records' do
      it 'returns the count of completed records' do
        completed_records = req.holdings_records.where(
          wc_retrieved: true,
          ht_retrieved: true
        )
        expected_count = completed_records.count
        expect(req.completed_count).to eq(expected_count)
      end
    end

    context 'all complete' do
      context 'without errors' do
        include_context 'complete HoldingsRequest'
        it_behaves_like 'counting completed records'
      end

      context 'with errors' do
        include_context 'complete HoldingsRequest with errors'
        it_behaves_like 'counting completed records'
      end
    end

    context 'partially complete' do
      context 'without errors' do
        include_context('incomplete HoldingsRequest')
        it_behaves_like 'counting completed records'
      end

      context 'with errors' do
        include_context 'incomplete HoldingsRequest with errors'
        it_behaves_like 'counting completed records'
      end
    end
  end

  describe :error_count do
    shared_examples 'counting records with errors' do
      it 'counts both HathiTrust and WorldCat errors' do
        expected_count = req.holdings_records.where.not(wc_error: nil, ht_error: nil).count
        expect(req.error_count).to eq(expected_count)
      end
    end

    context 'complete' do
      include_context 'complete HoldingsRequest with errors'
      it_behaves_like 'counting records with errors'
    end

    context 'incomplete' do
      include_context 'incomplete HoldingsRequest with errors'
      it_behaves_like 'counting records with errors'
    end
  end
end
