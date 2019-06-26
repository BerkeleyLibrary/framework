class GalcRequestForm < Form

  ALLOWED_PATRON_AFFILIATIONS = [
    Patron::Affiliation::UC_BERKELEY,
    #Patron::Affiliation::COMMUNITY_COLLEGE, #including this option for when testing
  ]

  ALLOWED_PATRON_TYPES = [
    Patron::Type::UNDERGRAD,
    Patron::Type::UNDERGRAD_SLE,
    Patron::Type::GRAD_STUDENT,
    Patron::Type::FACULTY,
    Patron::Type::MANAGER,
    Patron::Type::LIBRARY_STAFF,
    Patron::Type::STAFF,
    #Patron::Type::VISITING_SCHOLAR, #including this option for when testing
  ]

  # Patron making the request
  # @return [Patron::Record]
  attr_accessor :patron
  validates :patron, presence: true, strict: Error::PatronNotFoundError

  # @!attribute [r] patron_type
  #   @return [Patron::Type]
  delegate :type, to: :patron, prefix: true
  validates :patron_type, inclusion: {in: ALLOWED_PATRON_TYPES},
    strict: Error::ForbiddenError

  # @!attribute [r] patron_affiliation
  #   @return [Patron::Affiliation]
  delegate :affiliation, to: :patron, prefix: true
  validates :patron_affiliation, inclusion: {in: ALLOWED_PATRON_AFFILIATIONS},
    strict: Error::ForbiddenError

  # @!attribute [string] patron_email
  attr_accessor :patron_email
  validates :patron_email, email: true

  # @!attribute [string] patron_id
  delegate :id, to: :patron, prefix: true
  validates :patron_id, presence: true

  # @!attribute [string] patron_name
  delegate :name, to: :patron, prefix: true
  validates :patron_name, presence: true

  # Users must explicitly opt-in to each clause of the form.
  attr_accessor :borrow_check, :fine_check
  validates :borrow_check, :fine_check,
    inclusion: { in: %w(checked) }

  attr_accessor :support_email

  def support_email
    @support_email ||= 'webman@library.berkeley.edu'
  end

  #Cannot use the delegate method because that is for read-only attributes
  def patron_email
    @patron_email ||= @patron.email if @patron
  end

private

  def submit
    GalcRequestJob.perform_later(
      patron: {
        email: patron_email,
        id: patron_id,
        name: patron_name,
      },
    )
  end
end
