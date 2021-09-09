class ValidateProxyPatronController < ApplicationController
  protect_from_forgery with: :null_session
  before_action :alma_id, :alma_password, only: [:index]

  def index
    if AlmaServices::Patron.authenticate_alma_patron(alma_id, alma_password)
      if AlmaServices::Patron.valid_proxy_patron?(alma_id)
        render plain: 'Success'
      else
        render plain: 'Fail', status: :forbidden
      end
    else
      render plain: 'Fail', status: :forbidden
    end
  end

  private

  def alma_id
    params.require(:alma_id)
  end

  def alma_password
    params.require(:alma_password)
  end

end
