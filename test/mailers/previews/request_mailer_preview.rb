# Preview all emails at http://localhost:3000/rails/mailers/request_mailer
class RequestMailerPreview < ActionMailer::Preview
  def ucop_borrow_request_form_preview
    @borrow_request = UcopBorrowRequestForm.new(
      employee_name: 'Fiona',
      employee_preferred_name: 'Fifi',
      department_name: 'Merritt',
      employee_id: '1234',
      employee_email: 'spot@spca.org',
      employee_personal_email: 'being@home.org',
      employee_phone: '+1(123)456-7890',
      department_head_name: 'Vim',
      department_head_email: 'allthatjazz@yoshi.com',
    )

    RequestMailer.ucop_borrow_request_form_email(@borrow_request)
  end

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

  def confirmation_email_baker_preview
    RequestMailer.confirmation_email_baker('Charlie Christian',12345669)
  end

  def galc_confirmation_email
    RequestMailer.galc_confirmation_email('framework-test-recipient@berkeley.edu')
  end

  def galc_failure_email
    RequestMailer.galc_failure_email(
      "313135",
      "Dan Schmidt",
      "This is the note that would've been added",
    )
  end

  def opt_out_staff_preview
    RequestMailer.opt_out_staff('blinky@library.berkeley.edu',12345678,'Blinky','Kincaid')
  end
end
