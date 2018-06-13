class RequestMailer < ActionMailer::Base
  default from: 'lib-noreply@berkeley.edu'
#  layout 'confirmation_email'

  def failure_email(email,empid,firstname,lastname)
    @email = email 
    mail(to: @email, subject: 'alt-media scanning patron opt-in failure',body: "Was not able to update patron record for #{firstname} #{lastname} #{empid} to opt-in to altmedia scanning")
  end

  def confirmation_email(email)
    @email = email 
    #mail(to: @email, subject: 'Sample Email',body: 'your request is being processed')
    mail(to: @email, subject: 'alt-media scanning service opt-in')
  end

  def opt_out_staff(email,empid,firstname,lastname)
    @email = email 
    mail(to: @email, subject: 'alt-media scanning service opt-out',body: "#{firstname} #{lastname} #{empid} has opted out of the alt-media scanning service.")
  end

  def opt_out_faculty(email)
    @email = email 
    mail(to: @email, subject: 'alt-media scanning service opt-out',body: "You have successfully opted out of the alt-media scanning service.")
  end

end
