class ScanController < ApplicationController
require 'request_mailer'
require 'net/ssh'
require 'open-uri'
require 'socket'
require 'shellwords'

def entry
  @empId = session[:empId]
  #Send them to login page if session is not defined
  unless @empId
	  redirect_to root_path
	end

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

  #log it
  AltscanLog.debug "Opt-In"

  #ssh and call Expect script which will update the patron record with the note above
  fork do
    #internal note that will be added to patron record in Millennium
    now = Time.now.strftime("%Y%m%d")
    note = "#{now} library book scan eligible [litscript]"

    # Connection info, including credentials, sourced from rails config
    host = Rails.application.config.expect_url.host
    user = Rails.application.config.expect_url.user
    cmd  = [Rails.application.config.expect_url.path, note, emp_id].shelljoin
    opts = { non_interactive: true }

    res = Net::SSH.start(host, user, opts) { |ssh| ssh.exec!(cmd) }

    if res.match('Finished Successfully')
      RequestMailer.confirmation_email(faculty_email).deliver_now
    else
      #expect script failed send error to prntscan list
      RequestMailer.failure_email(emp_id,firstname,lastname,note).deliver_now
    end
  end

 	render("scan/optin")
 end

end

end
