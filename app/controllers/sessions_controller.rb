class SessionsController < ApplicationController
  def new
    redirect_to user_calnet_omniauth_authorize_path
  end

  def destroy
    reset_session
    redirect_to controller: :home
  end
end
