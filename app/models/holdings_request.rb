# rubocop:disable Metrics/ClassLength
# TODO: Move some code out of this class
class HoldingsRequest < ActiveRecord::Base
  include BerkeleyLibrary::Holdings

  # ------------------------------------------------------------
  # Constants

  # Batch size for inserting HoldingsRecords
  BATCH_SIZE = 10_000
  RESULT_ARGS = %i[oclc_number wc_symbols wc_error ht_record_url ht_error].freeze

  MSG_NO_OCLC_NUMBERS = 'No OCLC numbers found in input spreadsheet'.freeze

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
  # Class methods

  class << self
    # Creates a new HoldingsRequest, validates the attached input file, and
    # creates holdings records for each OCLC number.
    def create_from(**options)
      # This awkwardness is b/c we need the rollback to cancel
      # creating associated HoldingsRecords, but we still want
      # to return the created request
      request = nil
      transaction(requires_new: true) do
        request = create_with_records(**options)
        raise ActiveRecord::Rollback if request.errors.any?
      end
      request
    rescue StandardError
      # And this awkwardness is b/c ActiveStorage doesn't try to upload
      # the files till after the transaction commits, so if that fails
      # for some reason, we need to manually delete the record
      clean_up(request) if request && request.persisted?

      raise
    end

    private

    # @param request [HoldingsRequest] the request
    def clean_up(request)
      blob = (input_file = request.input_file).attached? ? input_file.blob : nil
      request.destroy
    ensure
      # If we were using S3 or whatever, this would be expensive
      # and we should use purge_later, but since we're using
      # local disk, let's just take care of it right now
      blob.purge if blob
    end

    # @return HoldingsRequest the request
    def create_with_records(input_file: nil, user: nil, **options)
      filename = filename_from(input_file)

      create(filename:, input_file:, **options).tap do |request|
        ensure_holdings_records(request, input_file:)
        ensure_admin_if_immediate(request, user:)
      end
    end

    def filename_from(input_file)
      # input_file can be an UploadedFile, or a hash -- see https://guides.rubyonrails.org/active_storage_overview.html#attaching-file-io-objects
      return input_file.original_filename if input_file.respond_to?(:original_filename)
      return input_file[:filename] if input_file.is_a?(Hash)
    end

    def clean_input_file_message(msg, input_file)
      if input_file.respond_to?(:path)
        msg.gsub(input_file.path, filename_from(input_file))
      else
        msg
      end
    end

    def ensure_holdings_records(request, input_file:)
      request.ensure_holdings_records! if request.persisted?
    rescue StandardError => e
      logger.error("Error creating holdings records from input file #{request.filename}", e)
      request.errors.add(:input_file, clean_input_file_message(e.message, input_file)) if request
    end

    def ensure_admin_if_immediate(request, user:)
      return unless request.immediate?
      return if user && user.framework_admin

      logger.error("Can't trigger immediate holdings request unless logged in as Framework admin", user:)
      request.errors.add(:immediate, I18n.t('activerecord.errors.models.holdings_task.attributes.immediate.forbidden'))
    end
  end

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

  def output_filename
    "#{File.basename(filename, '.*')}-processed.xlsx"
  end

  def record_count
    holdings_records.count
  end

  def completed_records
    conditions = {}.tap do |cnds|
      cnds[:ht_retrieved] = true if hathi?
      cnds[:wc_retrieved] = true if world_cat?
    end
    holdings_records.where(**conditions)
  end

  def completed_count
    completed_records.count
  end

  def error_count
    conditions = [].tap do |cnds|
      cnds << holdings_records.where.not(ht_error: nil) if hathi?
      cnds << holdings_records.where.not(wc_error: nil) if world_cat?
    end
    conditions.inject { |rel, cnd| rel.or(cnd) }.count
  end

  def first_completed_at
    completed_records.order(updated_at: :asc).limit(1).pick(:updated_at)
  end

  def last_completed_at
    completed_records.order(updated_at: :desc).limit(1).pick(:updated_at)
  end

  # ------------------------------------------------------------
  # Public instance methods

  def ensure_holdings_records!
    all_rows = each_input_oclc.map do |oclc_num|
      { holdings_request_id: id, oclc_number: oclc_num }
    end
    raise ArgumentError, MSG_NO_OCLC_NUMBERS if all_rows.empty?

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
    input_file_uploaded? ? input_file.open(&) : with_uploaded_input_file(&)
  end

  def search_wc_symbols
    return unless world_cat?

    [].tap do |symbols|
      symbols.concat(BerkeleyLibrary::Holdings::WorldCat::Symbols::RLF) if rlf?
      symbols.concat(BerkeleyLibrary::Holdings::WorldCat::Symbols::UC) if uc?
    end
  end

  def input_file_uploaded?
    input_file.attached? && input_file.service.exist?(input_file.key)
  end

  def output_file_uploaded?
    output_file.attached? && output_file.service.exist?(output_file.key)
  end

  def ensure_output_file!
    return if output_file_uploaded?

    write_output_file!
  end

  # ------------------------------------------------------------
  # Private methods

  private

  # Hack that lets us work with a newly uploaded input file before it's
  # been "uploaded" to ActiveStorage::Service::DiskService
  def with_uploaded_input_file
    return unless (uploaded_file = attachment_changes['input_file']&.attachable)

    # input_file can be an UploadedFile, or a hash -- see https://guides.rubyonrails.org/active_storage_overview.html#attaching-file-io-objects
    io = uploaded_file.is_a?(Hash) ? uploaded_file[:io] : uploaded_file

    begin
      yield io
    ensure
      io.rewind
    end
  end

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

  def input_spreadsheet
    with_input_tmpfile do |tmpfile|
      BerkeleyLibrary::Util::XLSX::Spreadsheet.new(tmpfile.path)
    end
  end

end
# rubocop:enable Metrics/ClassLength
