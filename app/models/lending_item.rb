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

  def iiif_item
    return unless iiif_dir

    IIIFItem.new(title: title, author: author, dir_path: File.join(iiif_final_dir, iiif_dir))
  end

  def create_iiif_item!
    raise ActiveRecord::RecordNotFound, "Source directory not found (tried: #{source_dirs.join(', ')})" unless source_dir

    iiif_dir = File.basename(source_dir)
    output_dir = File.join(iiif_final_dir, iiif_dir)
    IIIFItem.create_from(source_dir, output_dir, title: title, author: author).tap do
      self.iiif_dir = iiif_dir
      save(validate: false)
    end
  end

  def source_dir
    source_dirs.each { |dir| return dir if File.directory?(dir) }
  end

  # ------------------------------------------------------------
  # Custom validation methods

  def ils_record_present
    return if ILS_RECORD_FIELDS.any? { |f| send(f).present? }

    errors.add(:base, "At least one ILS record ID (#{ILS_RECORD_FIELDS.join(', ')} must be present")
  end

  def record_ids
    ILS_RECORD_FIELDS.lazy.map { |f| send(f) }.reject(&:nil?)
  end

  def citation
    record_id_str = ILS_RECORD_FIELDS.filter_map { |f| "#{f}: #{send(f)}" if send(f) }.join(', ')
    "#{author}, #{title} (barcode: #{barcode}, #{record_id_str})"
  end

  private

  def source_dirs
    record_ids.map { |record_id| File.join(iiif_source_dir, "#{record_id}_#{barcode}") }
  end

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

  def active_loans
    lending_item_loans.active.order(:due_date)
  end
end
