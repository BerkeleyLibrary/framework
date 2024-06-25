class DoemoffPatronEmailForm < Form
  attr_accessor(
    :patron_email,
    :patron_message,
    :sender,
    :recipient_email
  )

  validates :patron_email,
            email: true,
            presence: true

  validates :patron_message, :sender, :recipient_email, presence: true

  private

  def submit
    RequestMailer.doemoff_patron_email(self).deliver_now
  end
end
