class ApplicationController < ActionController::Base
  helper_method :authenticated?

  protect_from_forgery with: :exception

  def new_session_path(scope)
    new_user_session_path
  end

  def authenticated?
    not session[:user].nil? and not session[:user].empty?
  end

  def authenticate!
    redirect_to new_user_session_path unless authenticated?
  end
end
