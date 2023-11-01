require 'jwt'
# Model used to bundle jwt, email, name for emailing the
# "invoice". The invoice is really just a link to Framework
# to view and select fees to then pay via PayPal

class EfeesInvoice
  include ActiveModel::Model

  attr_accessor :alma_id
  attr_accessor :name
  attr_accessor :email
  attr_accessor :jwt
  attr_accessor :fees

  validates :alma_id,
            presence: true

  class << self
    def decode(token)
      JWT.decode token, secret, true, { algorithm: 'HS256' }
    end

    def secret
      Rails.application.secrets.secret_key_base
    end
  end

  def initialize(alma_id)
    user = Alma::User.find_if_exists alma_id

    @alma_id = user.id
    @email = user.email
    @name = user.name
    @fees = user.fees
    @jwt = encode
  end

  def encode
    JWT.encode payload, EfeesInvoice.secret, 'HS256'
  end

  def submit!
    # Send the email with the link to the user!
    RequestMailer.efee_invoice_email(self).deliver_now
  end

  private

  def payload
    # Why "userName" and not "Alma_ID"...?
    # This JWT is going to be used by the same code that processes the
    # request from Alma... Alma passes the "Alma_ID" as "userName"...a little weird.
    { userName: alma_id }
  end

end
