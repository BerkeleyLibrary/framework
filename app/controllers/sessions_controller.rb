class SessionsController < ApplicationController
  def new
    redirect_to "/auth/calnet"
  end

  def callback
    @user = User.new(
      display_name: auth_params["extra"]['displayName'],
      employee_id: auth_params["extra"]['employeeNumber'],
      uid: auth_params["uid"],
    )

    sign_in @user

    redirect_to request.env['omniauth.origin'] || home_path
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
