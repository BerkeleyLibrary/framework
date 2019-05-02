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
  validates :patron, presence: true, strict: Error::ForbiddenError

   # @!attribute [string] display_name
  attr_accessor :display_name
  validates :display_name, presence: true

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

  # @!attribute [array] patron_notes
  #   @return [Patron::Notes]
  attr_accessor :patron_notes
  validate :note_validate!

  # Users must explicitly opt-in to each clause of the form.
  attr_accessor :borrow_check, :fine_check
  validates :borrow_check, :fine_check,
    inclusion: { in: %w(checked) }

  # @!attribute [object] publication

  #Fields that are not required but can be optionally filled out by the user
  #attr_accessor :pub_location, :issn, :author, :pages, :pub_notes

  attr_accessor :support_email

  def support_email
    @support_email ||= 'webman@library.berkeley.edu'
  end

  #Cannot use the delegate method because that is for read-only attributes
  def patron_email
    @patron_email ||= @patron.email if @patron
  end

  #Sometimes the note field is a string and sometimes it is an array, so standardize it
  #Return an empty array if there is no notes field. Otherwise return an array of notes
  def patron_notes
    if patron.note.nil?
      patron_notes = []
    else
      patron.note.kind_of?(Array) ? patron.note : (patron_notes ||= []) << patron.note
    end
  end

  #Check to see if the patron's Millenium account contains a note with text indicating eligibility
  def is_eligible?
    #patron_notes.grep(/GALC eligible/).any?
    patron_notes.grep(/GALC eligible/).any?
  end

  #Raise errors depending on both eligibility and patron type
  def note_validate!
    raise Error::GalcNoteError if not is_eligible?
  end

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
    GalcRequestJob.perform_later(
      support_email,
      publication,
      patron: {
        email: patron_email,
        id: patron_id,
        name: display_name,
      },
    )
  end
end