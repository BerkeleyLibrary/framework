class OmniauthCallbacksController < Devise::OmniauthCallbacksController
  def calnet
    logger.info(request.env["omniauth.auth"].inspect)

    session[:user] = User.new(
      display_name: request.env["omniauth.auth"]["extra"]['displayName'],
      employee_id: request.env["omniauth.auth"]["extra"]['employeeNumber'],
      uid: request.env["omniauth.auth"]["uid"],
    )

    redirect_to new_scan_request_form_path
  rescue StandardError => e
    logger.error "Calnet | ERROR: #{e.inspect}"
    flash[:danger] = t('.forbidden')
    redirect_to root_path
  end
end
