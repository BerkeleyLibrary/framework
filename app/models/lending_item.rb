class LendingItem < ActiveRecord::Base
  validates :barcode, presence: true
  validates :filename, presence: true
  validates :title, presence: true
  validates :author, presence: true
  validates :copies, numericality: { greater_than_or_equal_to: 0 }
  validate :ils_record_present

  # ------------------------------------------------------------
  # Custom validation methods

  def ils_record_present
    ils_record_fields = [:millennium_record, :alma_record]
    return if ils_record_fields.any? { |f| send(f).present? }
    errors.add(:base, "At least one ILS record ID (#{ils_record_fields.join(', ')} must be present")
  end
end
