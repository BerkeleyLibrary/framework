class HoldingsTask < ActiveRecord::Base
  include BerkeleyLibrary::Holdings

  # ------------------------------------------------------------
  # Constants

  # Batch size for inserting HoldingsRecords
  BATCH_SIZE = 10_000
  RESULT_ARGS = %i[oclc_number wc_symbols wc_error ht_record_url ht_error].freeze

  # ------------------------------------------------------------
  # Relations

  has_one_attached :input_file
  has_one_attached :output_file

  has_many :holdings_records, dependent: :delete_all

  # ------------------------------------------------------------
  # Validations

  validates :email, presence: true
  validates :filename, presence: true
  validate :options_selected

  # ------------------------------------------------------------
  # Synthetic accessors

  def world_cat?
    rlf? || uc?
  end

  def incomplete?
    wc_incomplete? || hathi_incomplete?
  end

  def hathi_incomplete?
    hathi? && holdings_records.exists?(ht_retrieved: false)
  end

  def wc_incomplete?
    world_cat? && holdings_records.exists?(wc_retrieved: false)
  end

  # ------------------------------------------------------------
  # Public instance methods

  def ensure_holdings_records!
    all_rows = each_input_oclc.map do |oclc_num|
      { holdings_task_id: id, oclc_number: oclc_num }
    end

    # Insert in batches to prevent DB connection timeout on very large datasets
    all_rows.each_slice(BATCH_SIZE) do |rows|
      # rubocop:disable Rails/SkipsModelValidations
      HoldingsRecord.insert_all(rows)
      # rubocop:enable Rails/SkipsModelValidations
    end
  end

  def each_input_oclc(&)
    with_input_tmpfile do |tmpfile|
      reader = BerkeleyLibrary::Holdings::XLSXReader.new(tmpfile.path)
      reader.each_oclc_number(&)
    end
  end

  def with_input_tmpfile(&)
    input_file.open(&)
  end

  def search_wc_symbols
    return unless world_cat?

    [].tap do |symbols|
      symbols.concat(BerkeleyLibrary::Holdings::WorldCat::Symbols::RLF) if rlf?
      symbols.concat(BerkeleyLibrary::Holdings::WorldCat::Symbols::UC) if uc?
    end
  end

  def ensure_output_file!
    return if output_file.attached?

    write_output_file!
  end

  # ------------------------------------------------------------
  # Private methods

  private

  def options_selected
    return if world_cat? || hathi?

    errors.add(:base, 'At least one of RLF, Other UC, or HathiTrust must be selected')
  end

  def new_result(oclc_number, wc_sym_str, wc_error, ht_record_url, ht_error)
    wc_symbols = (wc_sym_str ? wc_sym_str.split(',') : [])
    HoldingsResult.new(oclc_number, wc_symbols:, wc_error:, ht_record_url:, ht_error:)
  end

  def write_output_file!
    output_spreadsheet = input_spreadsheet.tap { |ss| write_results_to(ss) }

    output_file.attach(
      io: output_spreadsheet.stream,
      filename: output_filename,
      content_type: BerkeleyLibrary::Util::XLSX::Spreadsheet::MIME_TYPE_OOXML_WB,
      identify: false
    )
  end

  def write_results_to(ss)
    writer = XLSXWriter.new(ss, rlf:, uc:, hathi_trust: hathi)
    result_data = holdings_records.pluck(*RESULT_ARGS)
    result_data.each { |row| writer << new_result(*row) }
  end

  def output_filename
    "#{File.basename(filename, '.*')}-processed.xlsx"
  end

  def input_spreadsheet
    with_input_tmpfile do |tmpfile|
      BerkeleyLibrary::Util::XLSX::Spreadsheet.new(tmpfile.path)
    end
  end

end
