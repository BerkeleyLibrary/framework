class SessionsController < ApplicationController
	def new
#    return_url = params[:url] || request.referrer || root_path

    #redirect_to user_altmedia_omniauth_authorize_path(url: return_url)
    redirect_to user_altmedia_omniauth_authorize_path
  end

  def destroy
    reset_session
#    flash[:alert] = t('devise.sessions.signed_out')
    #redirect_to params[:url] || root_path
    redirect_to root_path
  end


end
