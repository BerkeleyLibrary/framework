class OmniauthCallbacksController < Devise::OmniauthCallbacksController
  # Sets session data following successful Calnet login
  def altmedia 
		@empid = request.env["omniauth.auth"]["extra"]['employeeNumber'].inspect    
		session[:empId] = request.env["omniauth.auth"]["extra"]['employeeNumber'].inspect 
  

    # The omniauth hash is an object that doesn't stringify nicely, so we have
    # to be explicit when debugging.
    logger.debug "Altmedia | Received callback (#{{
      credentials: request.env["omniauth.auth"]["credentials"],
      info: request.env["omniauth.auth"]["info"],
      provider: request.env["omniauth.auth"]["provider"],
      uid: request.env["omniauth.auth"]["uid"],
      name: request.env["omniauth.auth"]["displayName"],
      displayName: request.env["omniauth.auth"]["extra"]['displayName'],
    }.inspect})"

    
   # @user = User.from_altmedia!(request.env["omniauth.auth"])
   
   # sign_in @user
   # flash[:notice] = t('devise.sessions.signed_in')
    #redirect_to params[:url] || root_path
    redirect_to "/scan/entry" 
  rescue StandardError => e
    logger.error "Calnet | ERROR: #{e.inspect}"
    flash[:error] = t('omniauth.altmedia.failure')
    redirect_to root_path
  end
end
