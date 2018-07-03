class ScanController < ApplicationController
require 'request_mailer'
require 'net/ssh'
require 'open-uri'
require 'socket'

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
 emp_id = params[:emp_id]


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

  #internal note that will be added to patron record in Millennium  
  note = Time.now.strftime("%Y%m%d") + " library book scan eligible [litscript]"
  #command = '/home/dzuckerm/patronnote/mkcallnote.pl "'  + note + '" ' + emp_id 
  command = 'sudo -u lsomgr /usr/bin/perl -I /home/lsomgr/patronScripts/bin -I /home/lsomgr/perl5/lib/perl5 /home/lsomgr/patronScripts/bin/mkcallnote.pl "' + note + '" ' + emp_id 


  #ssh and call Expect script which will update the patron record with the note above 
  fork do
     Net::SSH.start( ENV['EXPECT'], ENV['SSH_USER'],:keys=> ENV['PUB_KEY'] ) do| ssh |
       result = ssh.exec! command 
       ssh.close
			 if result.match('Finished Successfully')
  		    RequestMailer.confirmation_email(faculty_email).deliver_now 
			 else
  		 	  #expect script failed send error to prntscan list
  		    RequestMailer.failure_email(emp_id,firstname,lastname,note).deliver_now 
       end
     end
  end

 	render("scan/optin")
 end

end

end
