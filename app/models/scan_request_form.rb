# Allow qualified academic patrons to request scans of documents
#
# This is commonly referred to as the "AltMedia" form.
class ScanRequestForm < Form
  ALLOWED_PATRON_AFFILIATIONS = [
    Patron::Affiliation::UC_BERKELEY,
  ]

  ALLOWED_PATRON_TYPES = [
    Patron::Type::FACULTY,
    Patron::Type::VISITING_SCHOLAR
  ]

  # Whether the user has opted in or out of the scanning service
  #
  # Note that in Ruby, only `nil` and `false` are falsey. Everything else,
  # including 0 and '0' and '', are truthy. Because we're dealing with an HTML
  # form, which only returns string values, we have to be careful about
  # typecasting here.
  #
  # @return [String]
  # @see http://ruby-doc.org/core-2.1.1/FalseClass.html
  attr_accessor :opt_in

  # Patron making the request
  # @return [Patron::Record]
  attr_accessor :patron

  # Display name of the patron making the request
  # @return [String]
  attr_accessor :patron_name

  # @!attribute [r] patron_affiliation
  #   @return [Patron::Affiliation]
  delegate :affiliation, to: :patron, prefix: true

  # @!attribute [r] patron_blocks
  #   @return [String, nil]
  delegate :blocks, to: :patron, prefix: true

  # @!attribute [r] patron_email
  #   @return [String]
  delegate :email, to: :patron, prefix: true

  # @!attribute [r] patron_id
  #   @return [String]
  delegate :id, to: :patron, prefix: true

  # @!attribute [r] patron_type
  #   @return [Patron::Type]
  delegate :type, to: :patron, prefix: true

  validates :opt_in,
    inclusion: { in: %w(true false) }

  validates :patron,
    presence: true,
    strict: Error::PatronNotFoundError

  validates :patron_affiliation,
    inclusion: { in: ALLOWED_PATRON_AFFILIATIONS },
    strict: Error::ForbiddenError

  validates :patron_blocks,
    absence: true,
    strict: Error::PatronBlockedError

  validates :patron_email,
    email: true,
    presence: true

  validates :patron_name,
    presence: true

  validates :patron_type,
    inclusion: { in: ALLOWED_PATRON_TYPES },
    strict: Error::ForbiddenError

  def opted_in?
    'true' == opt_in
  end

private

  def submit
    (opted_in? ? ScanRequestOptInJob : ScanRequestOptOutJob).perform_later(
      patron: {
        email: patron_email,
        id: patron_id,
        name: patron_name
      }
    )
  end
end
