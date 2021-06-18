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

  # TODO: Use Rails i18n
  MSG_UNAVAILABLE = 'There are no available copies of this item.'.freeze
  MSG_UNPROCESSED = 'This item has not yet been processed for viewing.'.freeze

  # ------------------------------------------------------------
  # Class methods

  class << self
    # @return LendingItem::ActiveRecord_Relation
    def having_record_id(record_id)
      # TODO: get rid of Millennium IDs and get rid of this
      ILS_RECORD_FIELDS.inject(nil) do |conditions, f|
        cond = where(f => record_id)
        conditions.nil? ? cond : conditions.or(cond)
      end
    end
  end

  # ------------------------------------------------------------
  # Instance methods

  def available?
    copies_available > 0
  end

  def processed?
    !iiif_dir.nil?
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

    Lending::IIIFItem.new(title: title, author: author, dir_path: iiif_dir_actual)
  end

  def iiif_record_id
    # TODO: something less awful
    return unless iiif_dir

    iiif_dir.delete_suffix("_#{barcode}")
  end

  def create_iiif_item!
    raise ActiveRecord::RecordNotFound, "Source directory not found (tried: #{source_dirs.join(', ')})" unless source_dir

    self.iiif_dir = File.basename(source_dir)
    Lending::IIIFItem.create_from(source_dir, iiif_dir_actual, title: title, author: author).tap do
      save(validate: false)
    end
  end

  def source_dir
    source_dirs.each { |dir| return dir if File.directory?(dir) }
  end

  def iiif_dir_actual
    iiif_dir && File.join(iiif_final_dir, iiif_dir)
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

  # TODO: move this to a utility class
  def iiif_source_dir
    Rails.application.config.iiif_source_dir.tap do |dir|
      raise ArgumentError, 'iiif_source_dir not set' if dir.blank?
      raise ArgumentError, "iiif_source_dir #{dir} is not a directory" unless File.directory?(dir)
    end
  end

  # TODO: move this to a utility class
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
