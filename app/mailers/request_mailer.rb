class RequestMailer < ActionMailer::Base
  default from: 'lib-noreply@berkeley.edu'

  # Sends the UcopBorrowRequestForm
  def ucop_borrow_request_form_email(borrow_request)
    @borrow_request = borrow_request

    mail(to: borrow_request.department_head_email)
  end

  # Send LibstaffEdevicesLoanRequest confirmation email to user
  def libdevice_confirmation_email(email)
    mail(to: email)
  end

  # Send email describing a failure of the LibstaffEdevicesLoanRequest job
  def libdevice_failure_email(empid, displayname, note)
    @empid = empid
    @displayname = displayname
    @note = note

    mail(to: admin_to)
  end

  def doemoff_room_confirmation_email(email)
    mail(to: email)
  end

  # Send email describing a failure of the DoemoffStudyRoomUse job
  def doemoff_room_failure_email(empid, displayname, note)
    p "what's going on??!!"
    @empid = empid
    @displayname = displayname
    @note = note

    mail(to: admin_to)
  end

  # Send email describing a failure of a ScanRequest job
  def failure_email(empid, displayname, note)
    @empid = empid
    @displayname = displayname
    @note = note

    mail(to: admin_to)
  end

  # Send ScanRequest confirmation email to the opted-in user
  def confirmation_email(email)
    mail(to: email)
  end

  # Send ScanRequest confirmation email to the admins
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
