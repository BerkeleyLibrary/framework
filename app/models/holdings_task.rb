class HoldingsTask < ActiveRecord::Base

  # ------------------------------------------------------------
  # Constants

  # Batch size for inserting HoldingsRecords
  BATCH_SIZE = 10_000

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

  # ------------------------------------------------------------
  # Private methods

  private

  def options_selected
    return if world_cat? || hathi?

    errors.add(:base, 'At least one of RLF, Other UC, or HathiTrust must be selected')
  end
end
