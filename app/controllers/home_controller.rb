# Renders the /home page
#
# We'll likely be asked to remove this at some point, but for now it's useful
# to have in development.
class HomeController < ApplicationController
  def index; end

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
