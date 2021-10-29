# Handle user sessions and omniauth (CAS) callbacks
#
# When a user attempts to access a restricted resource, we redirect them (via
# an {ErrorHandling} hook) to the #new action. This sets the return url, if
# it's known, and forwards them on to Calnet for authentication. Calnet
# returns them (via Omniauth) to the #callback method, which stores their
# info into the session.
#
# The nitty gritty of Calnet authentication is handled mostly by Omniauth.
#
# @see https://github.com/omniauth/omniauth
class SessionsController < ApplicationController
  # Redirect the user to Calnet for authentication
  def new
    redirect_args = { origin: params[:url] || home_path }.to_query
    redirect_to "/auth/calnet?#{redirect_args}"
  end

  # Generate a new user session using data returned from a valid Calnet login
  def callback
    logger.debug({ msg: 'Received omniauth callback', omniauth: auth_params })

    @user = User.from_omniauth(auth_params).tap do |user|
      sign_in(user)
      log_signin(user)
    end

    redirect_to request.env['omniauth.origin'] || home_path
  end

  # Logout the user by redirecting to CAS logout screen
  def destroy
    sign_out

    # TODO: configure this more elegantly and make it play better with Selenium tests
    redirect_to "https://auth#{'-test' unless Rails.env.production?}.berkeley.edu/cas/logout"
  end

  private

  def auth_params
    request.env['omniauth.auth']
  end

  def log_signin(user)
    logger.debug({ msg: 'Signed in user', user: user })
  end
end
