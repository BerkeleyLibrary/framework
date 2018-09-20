class ApplicationMailer < ActionMailer::Base
  default from: 'lib-noreply@berkeley.edu'

  def send_email(email)
    @email = email
    mail(to: @email, subject: 'Sample Email',body: 'testing')
  end
end
