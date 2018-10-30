class SessionsController < ApplicationController
  def new
    redirect_args = { origin: params[:url] || home_path }.to_query
    redirect_to "/auth/calnet?#{redirect_args}"
  end

  def callback
    logger.debug({
      message: "Received omniauth callback",
      omniauth: auth_params,
    }.to_json)

    @user = User.from_omniauth(auth_params)

    sign_in @user

    redirect_to params[:url] || request.env['omniauth.origin'] || home_path
  end

  def destroy
    sign_out
    redirect_to home_path
  end

  def failure
    flash[:danger] = t('.forbidden')
    redirect_to home_path
  end

  private

  def auth_params
    request.env["omniauth.auth"]
  end
end
