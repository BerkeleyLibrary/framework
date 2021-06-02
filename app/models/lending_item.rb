class LendingItem < ActiveRecord::Base

  # ------------------------------------------------------------
  # Validations

  validates :barcode, presence: true
  validates :filename, presence: true
  validates :title, presence: true
  validates :author, presence: true
  validates :copies, numericality: { greater_than_or_equal_to: 0 }
  validate :ils_record_present

  # ------------------------------------------------------------
  # Constants

  ILS_RECORD_FIELDS = %i[millennium_record alma_record].freeze

  # ------------------------------------------------------------
  # Custom validation methods

  def ils_record_present
    return if ILS_RECORD_FIELDS.any? { |f| send(f).present? }

    errors.add(:base, "At least one ILS record ID (#{ILS_RECORD_FIELDS.join(', ')} must be present")
  end
end
