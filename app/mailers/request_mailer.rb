class RequestMailer < ApplicationMailer
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
    @empid = empid
    @displayname = displayname
    @note = note

    mail(to: admin_to)
  end

  # Send ServiceArticleRequest confirmation email to user
  # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
  def service_article_confirmation_email(email, publication, patron)
    @pub_title = publication[:pub_title]
    @pub_location = publication[:pub_location]
    @issn = publication[:issn]
    @vol = publication[:vol]
    @article_title = publication[:article_title]
    @author = publication[:author]
    @pages = publication[:pages]
    @citation = publication[:citation]
    @pub_notes = publication[:pub_notes]

    @patron_name = patron.name
    @patron_email = patron.email

    mail(to: email)
  end
  # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

  # Send email describing a failure of the ServiceArticleRequest job
  def service_article_failure_email(empid, displayname)
    @empid = empid
    @displayname = displayname

    mail(to: admin_to)
  end

  # Send StudentEdevicesLoanJob confirmation email to user
  def student_edevices_confirmation_email(email)
    mail(to: email)
  end

  # Send email describing a failure of the StudentEdevicesLoanJob job
  def student_edevices_failure_email(empid, displayname, note)
    @empid = empid
    @displayname = displayname
    @note = note

    mail(to: admin_to)
  end

  # Send GalcRequest confirmation email to user
  def galc_confirmation_email(email)
    mail(to: email, subject: 'GALC confirmation email')
  end

  # Send email describing a failure of the GalcRequest job
  def galc_failure_email(empid, displayname, note)
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

  def opt_out_staff(empid, displayname)
    @empid = empid
    @displayname = displayname

    mail(cc: [admin_to, confirm_to])
  end

  def opt_out_faculty(email)
    mail(to: email)
  end
end
