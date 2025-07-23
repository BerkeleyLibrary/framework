class ValidateProxyPatronController < ApplicationController
  skip_forgery_protection

  def index
    authenticate_alma_patron!
    check_proxy_privileges!
    render plain: 'Success'
  rescue Error::PatronApiError
    render plain: 'Fail', status: :forbidden
  end

  private

  def alma_id
    params.require(:alma_id)
  end

  def alma_password
    params.require(:alma_password)
  end

  def authenticate_alma_patron!
    return if AlmaServices::Patron.authenticate_alma_patron?(alma_id, alma_password)

    logger.warn("Unable to authenticate Alma patron #{alma_id.inspect}")
    raise Error::PatronNotFoundError
  end

  def check_proxy_privileges!
    return if AlmaServices::Patron.valid_proxy_patron?(alma_id)

    logger.warn("Alma patron #{alma_id} is not a valid proxy user")
    raise Error::PatronNotProxyUserError
  end
end
