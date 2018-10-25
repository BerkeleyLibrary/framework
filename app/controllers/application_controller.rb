class ApplicationController < ActionController::Base
  include ErrorHandling

  before_action :set_support_email
  helper_method :authenticated?

  protect_from_forgery with: :exception

  def new_session_path(scope)
    new_user_session_path
  end

  def authenticated?
    not session[:user].blank?
  end

  def authenticate!
    if not authenticated?
      raise Framework::Errors::NotAuthenticatedError,
        "Endpoint #{controller_name}/#{action_name} requires authentication"
    end
  end

  def redirect_with_params(opts={})
    redirect_to request.parameters.update(opts)
  end

private

  def set_support_email
    @support_email = 'privdesk@library.berkeley.edu'
  end

end
