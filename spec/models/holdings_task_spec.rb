require 'rails_helper'

RSpec.describe HoldingsTask, type: :model do

  # ------------------------------------------------------------
  # Fixture

  # -------------------------------
  # static inputs

  let(:input_file_path) { 'spec/data/holdings/input-file.xlsx' }
  let(:input_file_basename) { File.basename(input_file_path) }
  let(:mime_type_xlsx) { BerkeleyLibrary::Util::XLSX::Spreadsheet::MIME_TYPE_OOXML_WB }

  # -------------------------------
  # helper methods

  def uploaded_file
    # Tempfile#path will return null if it's been unlinked (deleted)
    return @uploaded_file if @uploaded_file && @uploaded_file.path

    @uploaded_file = uploaded_file_from(input_file_path)
  end

  def uploaded_file_from(source_file)
    tmp = Tempfile.new.tap do |t|
      File.open(source_file, 'rb') { |f| IO.copy_stream(f, t) }
      t.rewind
    end

    ActionDispatch::Http::UploadedFile.new(
      tempfile: tmp,
      filename: File.basename(source_file),
      type: mime_type_xlsx
    )
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

  # ------------------------------------------------------------
  # Tests

  describe 'validation' do
    it 'accepts valid attributes' do
      task = HoldingsTask.new(**valid_attributes)
      expect(task).to be_valid
    end

    it 'requires an email address' do
      invalid_attributes = valid_attributes.except(:email)
      task = HoldingsTask.new(**invalid_attributes)
      expect(task).not_to be_valid
    end

    it 'requires a filename' do
      invalid_attributes = valid_attributes.except(:filename)
      task = HoldingsTask.new(**invalid_attributes)
      expect(task).not_to be_valid
    end

    it 'requires at least one option to be set' do
      invalid_attributes = valid_attributes.except(:rlf, :uc, :hathi)
      task = HoldingsTask.new(**invalid_attributes)
      expect(task).not_to be_valid
    end
  end

  describe :create do
    it 'accepts an input file' do
      task = HoldingsTask.create!(**valid_attributes)
      assert_same_contents(input_file_path, task.input_file)
    end

    it 'accepts an IO' do
      attributes = valid_attributes.except(:input_file)
      attributes[:input_file] = {
        io: File.open(input_file_path),
        filename: input_file_basename,
        content_type: mime_type_xlsx
      }

      task = HoldingsTask.create!(**attributes)
      assert_same_contents(input_file_path, task.input_file)
    end
  end

  describe :destroy do

    it 'destroys attached files' do
      task = HoldingsTask.create!(
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

      attachments = [task.input_file, task.output_file]
      storage_paths = attachments.map { |f| ActiveStorage::Blob.service.path_for(f.key) }

      storage_paths.each { |path| expect(File.exist?(path)).to eq(true) } # just to be sure

      task.destroy!

      storage_paths.each { |path| expect(File.exist?(path)).to eq(false) }
    end
  end

  describe :with_input_tmpfile do
    it 'yields a temporary file containing the input data' do
      expected_blob = File.binread(input_file_path)
      task = HoldingsTask.create!(**valid_attributes)

      actual_blob = task.with_input_tmpfile { |tmpfile| File.binread(tmpfile.path) }
      expect(actual_blob).to eq(expected_blob)
    end
  end

  describe :each_input_oclc do
    let(:oclc_numbers_expected) { File.readlines('spec/data/holdings/oclc_numbers_expected.txt', chomp: true) }

    attr_reader :task

    context 'success' do
      before do
        @task = HoldingsTask.create!(**valid_attributes)
      end

      it 'returns an enum' do
        en = task.each_input_oclc
        expect(en).to be_an(Enumerator)
        expect(en.to_a).to eq(oclc_numbers_expected)
      end

      it 'yields each OCLC number' do
        expect { |b| task.each_input_oclc(&b) }
          .to yield_successive_args(*oclc_numbers_expected)
      end
    end

    context 'failure' do
      it 'returns an empty enum for an empty input file' do
        input_file = uploaded_file_from('spec/data/holdings/input-file-empty.xlsx')
        attributes = valid_attributes.except(:input_file)
        attributes[:input_file] = input_file

        task = HoldingsTask.create!(**attributes)
        expect(task.each_input_oclc.to_a).to eq([])
      end

      it 'raises ArgumentError for an invalid input file' do
        input_file = uploaded_file_from('spec/data/holdings/input-file-excel95.xls')
        attributes = valid_attributes.except(:input_file)
        attributes[:input_file] = input_file

        task = HoldingsTask.create!(**attributes)
        expect { task.each_input_oclc }.to raise_error(ArgumentError)
      end
    end
  end

end
