class ServiceArticleRequestForm < Form
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
  delegate :type, to: :patron, prefix: true
  validates :patron_type, presence: true

  # @!attribute [string] patron_email
  delegate :email, to: :patron, prefix: true
  validates :patron_email, email: true

  # @!attribute [string] patron_id
  delegate :id, to: :patron, prefix: true
  validates :patron_id, presence: true

  # @!attribute [string] patron_note
  #   @return [Patron::Note]
  delegate :note, to: :patron, prefix: true

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

  #Check the patron Millenium record to see if the note includes text that grants access to the article scan service
  def eligible_note?
    if patron_note.nil?
      return false
    elsif patron_note.include? "book scan eligible"
      return true
    else
      return false
    end
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
