require 'lending/iiif_item'
require 'ucblit/util/uris'

class LendingItem < ActiveRecord::Base

  # ------------------------------------------------------------
  # Relations

  has_many :lending_item_loans

  # ------------------------------------------------------------
  # Validations

  validates :barcode, presence: true
  # TODO: rename :filename to :directory or something
  validates :filename, presence: true
  validates :title, presence: true
  validates :author, presence: true
  validates :copies, numericality: { greater_than_or_equal_to: 0 }
  validates_uniqueness_of :filename, scope: :barcode
  validate :ils_record_present

  # ------------------------------------------------------------
  # Constants

  # ILS record ID fields in order of preference
  ILS_RECORD_FIELDS = %i[alma_record millennium_record].freeze

  # ------------------------------------------------------------
  # Instance methods

  def available?
    copies_available > 0
  end

  def copies_available
    (copies - lending_item_loans.where(loan_status: :active).count)
  end

  def due_dates
    active_loans.pluck(:due_date)
  end

  def next_due_date
    return unless (next_loan_due = active_loans.first)

    next_loan_due.due_date
  end

  def source_dir
    possible_iiif_source_dirs.select { |f| File.directory?(f) }.first
  end

  def processed?
    !manifest_path.nil?
  end

  def manifest_path
    possible_iiif_final_dirs.map { |dir| File.join(dir, IIIFItem::MANIFEST_NAME) }.select { |p| File.file?(p) }.first
  end

  def process!
    # TODO: avoid double-processing
    iiif_item = create_iiif_item
    iiif_item.write_manifest!(manifest_root_url, iiif_base_url)
  end

  # ------------------------------------------------------------
  # Custom validation methods

  def ils_record_present
    return if ILS_RECORD_FIELDS.any? { |f| send(f).present? }

    errors.add(:base, "At least one ILS record ID (#{ILS_RECORD_FIELDS.join(', ')} must be present")
  end

  private

  def iiif_source_dir
    Rails.config.iiif_source_dir.tap do |dir|
      raise ArgumentError, 'iiif_source_dir not set' if dir.blank?
      raise ArgumentError, "iiif_source_dir #{dir} is not a directory" unless File.directory?(dir)
    end
  end

  def iiif_final_dir
    Rails.config.iiif_final_dir.tap do |dir|
      raise ArgumentError, 'iiif_final_dir not set' if dir.blank?
      raise ArgumentError, "iiif_final_dir #{dir} is not a directory" unless File.directory?(dir)
    end
  end

  def iiif_base_url
    Rails.config.iiif_base_uri.tap do |url|
      raise ArgumentError, 'iiif_base_uri not set' if url.blank?
    end
  end

  def create_iiif_item
    raise ArgumentError, "No source directory found for item (tried: #{possible_iiif_source_dirs.join(', ')})" unless source_dir

    final_dir = possible_iiif_source_dirs.select { |d| d.basename == source_dir.basename }.first
    Lending::IIIFItem.create_from(source_dir, final_dir, title: title, author: author)
  end

  # TODO: Just put relative paths in the DB
  # @return Lazy::Enumerator<String> Possible IIIF source directories based on record ID
  def possible_iiif_source_dirs
    record_ids.map { |record_id| File.join(iiif_source_dir, "#{record_id}_#{barcode}") }
  end

  # TODO: Just put relative paths in the DB
  # @return Lazy::Enumerator<String> Possible IIIF source directories based on record ID
  def possible_iiif_final_dirs
    raise ArgumentError, 'iiif_final_dir not set' if (iiif_final_dir = Rails.config.iiif_final_dir).blank?

    record_ids.map { |record_id| File.join(iiif_final_dir, "#{record_id}_#{barcode}") }
  end

  def record_ids
    ILS_RECORD_FIELDS.lazy.map { |f| send(f) }.reject(&:nil?)
  end

  def active_loans
    lending_item_loans.active.order(:due_date)
  end
end
