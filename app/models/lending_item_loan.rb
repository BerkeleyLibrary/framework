class LendingItemLoan < ActiveRecord::Base

  # ------------------------------------------------------------
  # Constants

  LOAN_DURATION_HOURS = 24 # TODO: make this configurable

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
  validates :patron_identifier, uniqueness: { scope: %i[lending_item loan_status] }
  validate :item_available

  # ------------------------------------------------------------
  # Callbacks

  after_find { |loan| loan.return! if loan.expired? }

  # ------------------------------------------------------------
  # Instance methods

  def return!
    self.loan_status = :complete
    self.return_date = Time.now.utc
    save!
  end

  def expired?
    due_date <= Time.now.utc
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

  def item_available
    return if lending_item.available?

    errors.add(:base, 'No copies available')
  end
end
