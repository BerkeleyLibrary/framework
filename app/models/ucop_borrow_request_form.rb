class UcopBorrowRequestForm
  include ActiveModel::Model

  attr_accessor(
    :department_head_email,
    :department_head_name,
    :department_name,
    :employee_email,
    :employee_id,
    :employee_name,
    :employee_personal_email,
    :employee_phone,
    :employee_preferred_name,
  )

  validates :department_name,
    presence: true

  validates :department_head_email,
    presence: true,
    format: { with: URI::MailTo::EMAIL_REGEXP }

  validates :employee_email,
    presence: true,
    format: { with: URI::MailTo::EMAIL_REGEXP }

  validates :employee_personal_email,
    presence: true,
    format: { with: URI::MailTo::EMAIL_REGEXP }

  validates :employee_phone,
    presence: true

  validates :employee_name,
    presence: true

  def submit!
    validate!

    RequestMailer.ucop_borrow_request_form_email(self).deliver_now
  end
end
