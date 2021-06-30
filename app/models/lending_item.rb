require 'lending'
require 'ucblit/util/uris'

class LendingItem < ActiveRecord::Base

  # ------------------------------------------------------------
  # Relations

  has_many :lending_item_loans

  # ------------------------------------------------------------
  # Validations

  validates :directory, presence: true
  validates_uniqueness_of :directory
  validates :title, presence: true
  validates :author, presence: true
  validates :copies, numericality: { greater_than_or_equal_to: 0 }
  validate :correct_directory_format

  # ------------------------------------------------------------
  # Constants

  LOAN_DURATION_HOURS = 2 # TODO: make this configurable

  # TODO: Use Rails i18n
  MSG_CHECKED_OUT = 'You have already checked out this item.'.freeze
  MSG_UNAVAILABLE = 'There are no available copies of this item.'.freeze
  MSG_UNPROCESSED = 'This item has not yet been processed for viewing.'.freeze

  # ------------------------------------------------------------
  # Instance methods

  # @return [LendingItemLoan] the created loan
  def check_out_to(patron_identifier)
    loan_date = Time.now.utc
    due_date = loan_date + LOAN_DURATION_HOURS.hours

    LendingItemLoan.create(
      lending_item_id: id,
      patron_identifier: patron_identifier,
      loan_status: :active,
      loan_date: loan_date,
      due_date: due_date
    )
  end

  def create_manifest(manifest_uri)
    iiif_item.create_manifest(manifest_uri, image_server_base_uri)
  end

  # ------------------------------------------------------------
  # Synthetic accessors

  def processed?
    return false if Dir.empty?(iiif_dir) # :empty? covers missing directories and non-directories

    Dir.entries(iiif_dir).any? { |e| Lending::Page.page_number?(e) }
  end

  def available?
    processed? && copies_available > 0
  end

  def copies_available
    (copies - lending_item_loans.where(loan_status: :active).count)
  end

  def checkout_disabled?
    !checkout_disabled_reason.nil?
  end

  def checkout_disabled_reason
    return LendingItem::MSG_UNPROCESSED unless processed?
    return LendingItem::MSG_UNAVAILABLE unless available?
  end

  def due_dates
    active_loans.pluck(:due_date)
  end

  def next_due_date
    return unless (next_loan_due = active_loans.first)

    next_loan_due.due_date
  end

  def iiif_item
    raise ActiveRecord::RecordNotFound, "Error loading manifest for #{citation}: #{MSG_UNPROCESSED}" unless processed?

    Lending::IIIFItem.new(title: title, author: author, dir_path: iiif_dir)
  end

  def iiif_dir
    @iiif_dir ||= begin
      iiif_dir_relative = File.join(iiif_final_dir, directory)
      File.absolute_path(iiif_dir_relative)
    end
  end

  def citation
    "#{author}, #{title} (#{directory})"
  end

  def record_id
    ensure_record_id_and_barcode
    @record_id
  end

  def barcode
    ensure_record_id_and_barcode
    @barcode
  end

  # ------------------------------------------------------------
  # Custom validators

  def correct_directory_format
    return if directory && directory.split('_').size == 2

    errors.add(:directory, 'directory should be in the format <bibliographic record id>_<item barcode>')
  end

  # ------------------------------------------------------------
  # Private methods

  private

  def ensure_record_id_and_barcode
    return if @record_id && @barcode

    @record_id, @barcode = directory.split('_')
  end

  # TODO: move this to a helper
  def iiif_final_dir
    Rails.application.config.iiif_final_dir.tap do |dir|
      raise ArgumentError, 'iiif_final_dir not set' if dir.blank?
      raise ArgumentError, "iiif_final_dir #{dir} is not a directory" unless File.directory?(dir)
    end
  end

  # TODO: move this to a helper
  def image_server_base_uri
    UCBLIT::Util::URIs.uri_or_nil(Rails.application.config.image_server_base_uri).tap do |uri|
      raise ArgumentError, 'image_server_base_uri not set' unless uri
    end
  end

  def active_loans
    lending_item_loans.active.order(:due_date)
  end
end
