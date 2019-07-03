# Renders the /home page
#
# We'll likely be asked to remove this at some point, but for now it's useful
# to have in development.
class HomeController < ApplicationController

  self.support_email = 'webman@library.berkeley.edu'

  def health
    check = HealthCheck.new
    render json: check, status: check.http_status_code
  end

  def admin
    authenticate!
    if not current_user.framework_admin
      raise Error::ForbiddenError,
        "Endpoint #{controller_name}/#{action_name} requires framework admin CalGroup"
    else
      render :admin
    end
  end
end
