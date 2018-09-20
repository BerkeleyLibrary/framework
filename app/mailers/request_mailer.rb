class RequestMailer < ActionMailer::Base
  default from: 'lib-noreply@berkeley.edu'

  # Sends the UcopBorrowRequestForm
  def ucop_borrow_request_form_email(borrow_request)
    @borrow_request = borrow_request

    mail(to: borrow_request.department_head_email)
  end

  #--------------------------
  def failure_email(empid, displayname, note)
    @empid = empid
    @displayname = displayname
    @note = note

    mail(to: admin_to)
  end

  def confirmation_email(email)
    mail(to: email)
  end

  def confirmation_email_baker(displayname, employee_id)
    @displayname = displayname
    @empid = employee_id
    mail(cc: [admin_to, confirm_to])
  end

  def opt_out_staff(empid, displayname)
    @empid = empid
    @displayname = displayname

    mail(cc: [admin_to, confirm_to])
  end

  def opt_out_faculty(email)
    mail(to: email)
  end

private

  def admin_to
    Rails.application.config.altmedia['mail_admin_email']
  end

  def confirm_to
    Rails.application.config.altmedia['mail_confirm_email']
  end
end
