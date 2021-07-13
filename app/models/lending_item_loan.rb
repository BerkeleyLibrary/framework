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
  validate :no_duplicate_checkouts
  validate :item_processed
  validate :item_available
  validate :item_active

  # ------------------------------------------------------------
  # Callbacks

  after_find { |loan| loan.return! if loan.expired? || loan.lending_item.copies == 0 }

  # ------------------------------------------------------------
  # Instance methods

  def return!
    self.loan_status = :complete
    self.return_date = Time.now.utc

    # no_duplicate_checkouts validation can cause a SystemStackError
    # when return! is triggered from after_find
    save(validate: false)
  end

  def expired?
    due_date && due_date <= Time.current
  end

  # ------------------------------------------------------------
  # Custom validation methods

  def no_duplicate_checkouts
    active_checkout = LendingItemLoan.find_by(lending_item_id: lending_item_id, patron_identifier: patron_identifier, loan_status: 'active')
    return if active_checkout.nil? || active_checkout.id == id

    errors.add(:base, LendingItem::MSG_CHECKED_OUT)
  end

  def item_processed
    return if lending_item.processed?

    errors.add(:base, LendingItem::MSG_UNPROCESSED)
  end

  def item_available
    return if lending_item.available?

    errors.add(:base, LendingItem::MSG_UNAVAILABLE)
  end

  def item_active
    return if lending_item.active?

    errors.add(:base, LendingItem::MSG_INACTIVE)
  end
end
