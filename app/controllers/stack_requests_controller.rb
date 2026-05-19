require 'time'

class StackRequestsController < ApplicationController

  self.support_email = 'privdesk-library@berkeley.edu'

  # TODO: do we still need this?
  def forbidden; end

  def index
    @user_is_admin = current_user.any_role?(Role.stackpass_admin, :framework_admin)
  end

end
