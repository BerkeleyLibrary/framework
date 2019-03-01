class ServiceArticleRequestForm < Form
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
  validates :patron_type, presence: true

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

  # @!attribute [string] pub_title
  attr_accessor :pub_title
  validates :pub_title, presence: true

  # @!attribute [string] vol
  attr_accessor :vol
  validates :vol, presence: true

  # @!attribute [string] article_title
  attr_accessor :article_title
  validates :article_title, presence: true

  # @!attribute [string] citation
  attr_accessor :citation
  validates :citation, presence: true

  #Fields that are not required but can be optionally filled out by the user
  attr_accessor :pub_location, :issn, :author, :pages, :pub_notes

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
      patron.note.kind_of?(Array) ? patron.note.join("") : (patron_notes ||= []) << patron.note
    end
  end

  #The UCB SLE undergrad which is type 2 has access but all other student types need to be checked
  def is_student?
    patron.type == Patron::Type::GRAD_STUDENT or patron.type == Patron::Type::UNDERGRAD
  end

  #Faculty and students get specific views, as does all other patron types, so determine if the patron is "other"
  def is_other_patron_type?
    patron.type != Patron::Type::FACULTY and patron.type != Patron::Type::GRAD_STUDENT and patron.type != Patron::Type::UNDERGRAD
  end

  #Check to see if the patron's Millenium account contains a note with text indicating eligibility
  def is_eligible?
    patron_notes.grep(/book scan eligible/).any?
  end

  #Raise errors depending on both eligibility and patron type
  def note_validate!
    raise Error::FacultyNoteError if (not is_eligible? and patron.type == Patron::Type::FACULTY)
    raise Error::StudentNoteError if (not is_eligible? and is_student?)
    raise Error::GeneralNoteError if (not is_eligible? and is_other_patron_type?)
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

  #TO DO: ADD A MAILER JOB
  def submit
    Rails.logger.debug(self.to_json)
  end
end
