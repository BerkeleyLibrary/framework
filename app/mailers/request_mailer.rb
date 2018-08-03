class RequestMailer < ActionMailer::Base
  default from: 'lib-noreply@berkeley.edu'

  def failure_email(empid, displayname, note)
    @empid = empid
    @displayname = displayname
    @note = note

    mail(to: admin_to, subject: 'alt-media scanning patron opt-in failure')
  end

  def confirmation_email(email)
    mail(to: email, subject: 'alt-media scanning service opt-in')
  end

  def confirmation_email_baker(displayname,employee_id)
    @displayname = displayname
    @empid = employee_id
    mail(to: confirm_to, subject: 'alt-media scanning service opt-in')
  end

  def opt_out_staff(empid,displayname )
    @empid = empid
    @displayname = displayname

    mail(subject: 'alt-media scanning service opt-out')
  end

  def opt_out_faculty(email)
    mail(to: email, subject: 'alt-media scanning service opt-out')
  end

private

  def admin_to
    Rails.application.config.altmedia['mail_admin_email']
  end

  def confirm_to
    Rails.application.config.altmedia['mail_confirm_email']
  end
end
