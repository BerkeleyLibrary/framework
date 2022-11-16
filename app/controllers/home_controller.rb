# Renders the /home page
#
# We'll likely be asked to remove this at some point, but for now it's useful
# to have in development.
class HomeController < ApplicationController

  self.support_email = 'helpbox@library.berkeley.edu'

  # TODO: Move this to a HealthController that extends ActionController::API
  #       - note: may involve extracting some of ApplicationController into a mixin
  def health
    check = Health::Check.new
    render json: check, status: check.http_status_code
  end

  def admin
    authenticate!
    if current_user.framework_admin
      render :admin
    else
      raise Error::ForbiddenError,
            "Endpoint #{controller_name}/#{action_name} requires framework admin CalGroup"
    end
  end
end
