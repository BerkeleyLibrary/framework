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

  ILS_RECORD_FIELDS = %i[millennium_record alma_record].freeze

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

  # ------------------------------------------------------------
  # Custom validation methods

  def ils_record_present
    return if ILS_RECORD_FIELDS.any? { |f| send(f).present? }

    errors.add(:base, "At least one ILS record ID (#{ILS_RECORD_FIELDS.join(', ')} must be present")
  end

  private

  def active_loans
    lending_item_loans.active.order(:due_date)
  end
end
