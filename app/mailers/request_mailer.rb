require 'prawn'

# rubocop:disable Metrics/ClassLength
class RequestMailer < ApplicationMailer
  # Sends the AffiliateBorrowRequestForm
  def affiliate_borrow_request_form_email(borrow_request)
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

  # Send Proxy-Borrower Card Request Instructions to user
  def proxy_borrower_request_email(proxy_request)
    @proxy_request = proxy_request
    mail(to: @proxy_request.user_email)
  end

  # Send Proxy-Borrower Card Request Alert to privdesk
  def proxy_borrower_alert_email(proxy_request)
    @proxy_request = proxy_request
    mail(to: privdesk_to)
  end

  # Send Stack Pass Request Alert to privdesk
  def stack_pass_email(stackpass_form)
    @stackpass_form = stackpass_form
    mail(to: privdesk_to)
  end

  # Send Stack Pass Denial to requester
  def stack_pass_denied(stackpass_form)
    @stackpass_form = stackpass_form
    mail(to: @stackpass_form.email)
  end

  # Send Stack Pass Approval to requester
  def stack_pass_approved(stackpass_form)
    # Generate the Approval PDF File:
    pdf = stackpass_pdf(stackpass_form)

    # To write the pdf to a local file uncomment the following line:
    # pdf.render_file('approval_pass.pdf')

    attachments[pdf]
    mail(to: stackpass_form.email)
  end

  private

  # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
  def stackpass_pdf(stackpass_form)
    pdf = Prawn::Document.new
    pdf.move_down 10
    pdf.font_size 24
    pdf.text 'Gardner (MAIN) Stack Pass Approval', align: :center
    pdf.move_down 10
    pdf.font_size 12
    pdf.text 'Print out this Stack Pass or save it to your phone and bring it to the Doe Library,
              Gardner Stacks Level A along with a government-issued photo ID.', align: :center
    pdf.move_down 10
    pdf.text "Name: #{stackpass_form.name}", align: :center
    pdf.text "Date of Stack Pass: #{stackpass_form.pass_date.strftime('%m/%d/%Y')}", align: :center
    pdf.text "Approved by: #{stackpass_form.processed_by}", align: :center
    pdf.move_down 10
    pdf.text 'University of California, Berkeley Library'
  end
  # rubocop:enable Metrics/MethodLength, Metrics/AbcSize

end
# rubocop:enable Metrics/ClassLength
