class LendingItemLoan < ActiveRecord::Base

  # ------------------------------------------------------------
  # Constants

  LOAN_DURATION_HOURS = 2 # TODO: make this configurable

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
  validate :item_available

  # ------------------------------------------------------------
  # Callbacks

  after_find { |loan| loan.return! if loan.expired? }

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
    due_date && due_date <= Time.now.utc
  end

  # ------------------------------------------------------------
  # Class methods

  class << self
    def check_out(lending_item_id:, patron_identifier:)
      loan_date = Time.now.utc
      due_date = loan_date + LOAN_DURATION_HOURS.hours

      LendingItemLoan.create(
        lending_item_id: lending_item_id,
        patron_identifier: patron_identifier,
        loan_status: :active,
        loan_date: loan_date,
        due_date: due_date
      )
    end
  end

  # ------------------------------------------------------------
  # Custom validation methods

  def no_duplicate_checkouts
    active_checkout = LendingItemLoan.find_by(lending_item_id: lending_item_id, patron_identifier: patron_identifier, loan_status: 'active')
    return if active_checkout.nil? || active_checkout.id == id

    errors.add(:base, 'You have already checked out this item.')
  end

  def item_available
    return if lending_item.available?

    errors.add(:base, 'No copies available')
  end
end
