class LibstaffEdevicesLoanForm < Form
  ALLOWED_PATRON_AFFILIATIONS = [
    Patron::Affiliation::UC_BERKELEY,
    #Patron::Affiliation::COMMUNITY_COLLEGE, #including this option for when testing
  ]

  ALLOWED_PATRON_TYPES = [
    Patron::Type::LIBRARY_STAFF,
    #Patron::Type::VISITING_SCHOLAR, #including this option for when testing
  ]

  # Users must explicitly opt-in to each clause of the form.
  attr_accessor :borrow_check, :lending_check, :fines_check, :edevices_check
  validates :borrow_check, :lending_check, :fines_check, :edevices_check,
    inclusion: { in: %w(checked) }

  # Patron making the request
  # @return [Patron::Record]
  attr_accessor :patron
  validates :patron, presence: true, strict: Error::ForbiddenError

  # Display name of the patron making the request
  # @return [String]
  attr_accessor :display_name
  validates :display_name, presence: true

  # @!attribute [r] patron_type
  #   @return [Patron::Type]
  delegate :patron_type, to: :patron, prefix: true
  validates :patron_type, inclusion: {in: ALLOWED_PATRON_TYPES},
    strict: Error::ForbiddenError

  # @!attribute [string] patron_email
  delegate :email, to: :patron, prefix: true
  validates :patron_email, email: true

  # @!attribute [string] patron_id
  delegate :id, to: :patron, prefix: true
  validates :patron_id, presence: true

  # @!attribute [r] patron_affiliation
  #   @return [Patron::Affiliation]
  delegate :affiliation, to: :patron, prefix: true
  validates :patron_affiliation, inclusion: {in: ALLOWED_PATRON_AFFILIATIONS},
    strict: Error::ForbiddenError

  # @!attribute [r] patron_blocks
  #   @return [String, nil]
  delegate :blocks, to: :patron, prefix: true
  validates :patron_blocks, absence: true,
    strict: Error::PatronBlockedError

  # Apply strict (error-raising) validations
  def authorize!
    self.class.validators.select{|v| v.options[:strict]}.each do |validator|
      validator.attributes.each do |attribute|
        validator.validate_each(self, attribute, send(attribute))
      end
    end
  end

private

  def submit
    LibstaffEdevicesLoanJob.perform_later(
      patron: {
        email: patron_email,
        id: patron_id,
        name: display_name,
      },
    )
  end
end
