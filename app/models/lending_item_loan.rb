class LendingItemLoan < ActiveRecord::Base

  # ------------------------------------------------------------
  # Relations

  belongs_to :lending_item

  # ------------------------------------------------------------
  # Attribute restrictions

  enum loan_status: { pending: 'pending', active: 'active', complete: 'complete' }

  # ------------------------------------------------------------
  # Validations

  validates :lending_item, presence: true
  validates :patron_identifier, presence: true
end
