class DoemoffPatronEmailForm < Form
  ATTRIBUTES = %i[
    patron_email
    patron_message
    sender
    recipient_email
  ].freeze

  PatronEmail = Struct.new(*ATTRIBUTES, keyword_init: true)

  attr_accessor(*ATTRIBUTES)

  validates :patron_email,
            email: true,
            presence: true

  validates :patron_message, :sender, :recipient_email, presence: true

  def to_h
    ATTRIBUTES.index_with { |attr| public_send(attr) }
  end

  def submit!
    raise ActiveModel::ValidationError, self unless valid?

    RequestMailer.doemoff_patron_email(to_h).deliver_later
  end
end
