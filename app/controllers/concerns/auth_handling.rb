module AuthHandling
  extend ActiveSupport::Concern

  included do
    helper_method :authenticated?

    protect_from_forgery with: :exception
  end

  private

  def sign_in(user)
    session[:user] = user

    logger.debug({
      message: "Signed in user",
      user: session[:user],
    })
  end

  def sign_out
    reset_session
  end

  def current_user
    @current_user ||= User.new(session[:user] || {})
  end

  def authenticate!
    if not authenticated?
      raise Framework::Errors::NotAuthenticatedError,
        "Endpoint #{controller_name}/#{action_name} requires authentication"
    end
  end

  def authenticated?
    current_user.authenticated?
  end
end
