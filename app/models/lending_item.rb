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

  def generate_manifest(manifest_root_uri, image_server_base_uri)
    iiif_item.to_manifest(manifest_root_uri, image_server_base_uri)
  end

  # ------------------------------------------------------------
  # Synthetic accessors

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
    raise ActiveRecord::RecordNotFound, "Error loading manifest for #{citation}: #{MSG_UNPROCESSED}" unless processed

    Lending::IIIFItem.new(title: title, author: author, dir_path: iiif_dir)
  end

  def iiif_dir
    iiif_dir_relative = File.join(iiif_final_dir, directory)
    Dir.mkdir(iiif_dir_relative) unless File.directory?(iiif_dir_relative)
    File.realpath(iiif_dir_relative)
  end

  def citation
    "#{author}, #{title} (#{directory})"
  end

  # ------------------------------------------------------------
  # Private methods

  private

  # TODO: move this to a helper
  def iiif_final_dir
    Rails.application.config.iiif_final_dir.tap do |dir|
      raise ArgumentError, 'iiif_final_dir not set' if dir.blank?
      raise ArgumentError, "iiif_final_dir #{dir} is not a directory" unless File.directory?(dir)
    end
  end

  def active_loans
    lending_item_loans.active.order(:due_date)
  end
end
