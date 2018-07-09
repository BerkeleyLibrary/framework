class RequestMailer < ActionMailer::Base
  default from: 'lib-noreply@berkeley.edu'

  def failure_email(empid, firstname, lastname, note)
    @empid = empid
    @firstname = firstname
    @lastname = lastname
    @note = note

    mail(subject: 'alt-media scanning patron opt-in failure')
  end

  def confirmation_email(email)
    mail(to: email, subject: 'alt-media scanning service opt-in')
  end

  def opt_out_staff(empid, firstname, lastname)
    @empid = empid
    @firstname = firstname
    @lastname = lastname

    mail(subject: 'alt-media scanning service opt-out')
  end

  def opt_out_faculty(email)
    mail(to: email, subject: 'alt-media scanning service opt-out')
  end
end
