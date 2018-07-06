require 'request_mailer'

class ScanController < ApplicationController
  def entry
    @empId = session[:empId]
    #Send them to login page if session is not defined
    redirect_to root_path unless @empId

    session[:empId]
  end

  def scanrequest
    request_type = params[:request_type]
    lastname = params[:lastName]
    firstname = params[:firstName]
    faculty_email = params[:faculty_email]
    emp_id = params[:emp_id].gsub(/\D/, '')


    if request_type.eql?("optout")

      #send email to printscan and faculty who requested to opt-out
      RequestMailer.opt_out_staff(emp_id,firstname,lastname).deliver_now
      RequestMailer.opt_out_faculty(faculty_email).deliver_now

      #log it
      AltscanLog.debug "Opt-Out"

      render("scan/optout")
    elsif request_type.eql?("optin")
      AltscanLog.debug "Opt-In"

      UpdatePatronJob.perform_later(
        employee_id: emp_id,
        firstname: firstname,
        lastname: lastname,
        email: faculty_email,
      )

      render("scan/optin")
    end
  end

end
