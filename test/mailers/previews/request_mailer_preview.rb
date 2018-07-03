# Preview all emails at http://localhost:3000/rails/mailers/request_mailer
class RequestMailerPreview < ActionMailer::Preview
  def opt_out_faculty_preview 
    RequestMailer.opt_out_faculty("blinky@library.berkeley.edu")
  end

  def failure_email_preview
   now = Time.now.strftime("%Y%m%d")
   note = "#{now} library book scan eligible [litscript]"
   RequestMailer.failure_email('blinky@library.berkeley.edu',123456789,'Blinky','Kincaid',note)
	end

  def confirmation_email_preview
		RequestMailer.confirmation_email('blinky@library.berkeley.edu')
	end

	def opt_out_staff_preview
		RequestMailer.opt_out_staff('blinky@library.berkeley.edu',12345678,'Blinky','Kincaid')
	end

end
