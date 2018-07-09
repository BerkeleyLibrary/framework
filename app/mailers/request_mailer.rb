class RequestMailer < ActionMailer::Base
  default from: 'lib-noreply@berkeley.edu'
#  layout 'confirmation_email'

  def failure_email(empid,firstname,lastname,note)
	  @empid = empid
    @firstname = firstname
    @lastname = lastname
    @note = note
    #email = "prntscan@lists.berkeley.edu"
    #email = "dzuckerm@library.berkeley.edu"
    email = ENV['EMAIL_ADDR'] 
    mail(to: email, subject: 'alt-media scanning patron opt-in failure')
  end

  def confirmation_email(email)
    mail(to: email, subject: 'alt-media scanning service opt-in')
  end

  #def opt_out_staff(email,empid,firstname,lastname)
  def opt_out_staff(empid,firstname,lastname)
    @empid = empid
    @firstname = firstname
    @lastname = lastname
    #email = "prntscan@lists.berkeley.edu"
    #email = "dzuckerm@library.berkeley.edu"
    email = ENV['EMAIL_ADDR'] 
    #mail(to: email, subject: 'alt-media scanning service opt-out',body: "#{firstname} #{lastname} #{empid} has opted out of the alt-media scanning service.")
    mail(to: email, subject: 'alt-media scanning service opt-out')
  end

  def opt_out_faculty(email)
    mail(to: email, subject: 'alt-media scanning service opt-out')
  end

end
