# Mixins for authN/Z-related behaviors
module AuthHandling
  extend ActiveSupport::Concern

  included do
    helper_method :authenticated?

    protect_from_forgery with: :exception
  end

  private

  # Require that the current user be authenticated
  #
  # @return [void]
  # @raise [Framework::Errors::NotAuthenticatedError] If the user is not
  #   authenticated
  def authenticate!
    if not authenticated?
      raise Framework::Errors::NotAuthenticatedError,
        "Endpoint #{controller_name}/#{action_name} requires authentication"
    end
  end

  # Return whether the current user is authenticated
  #
  # @return [Boolean]
  def authenticated?
    current_user.authenticated?
  end

  # Return the current user
  #
  # This always returns a user object, even if the user isn't authenticated.
  # Call {User#authenticated?} to determine if they were actually auth'd, or
  # use the shortcut {#authenticated?} to see if the current user is auth'd.
  #
  # @return [User]
  def current_user
    @current_user ||= User.new(session[:user] || {})
  end

  # Sign in the user by storing their data in the session
  #
  # @param [User]
  # @return [void]
  def sign_in(user)
    session[:user] = user

    logger.debug({
      message: "Signed in user",
      user: session[:user],
    })
  end

  # Sign out the current user by clearing all session data
  #
  # @return [void]
  def sign_out
    reset_session
  end
end
