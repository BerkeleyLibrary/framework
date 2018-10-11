class UcopBorrowRequestForm
  include Submitable

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
    email: true

  validates :employee_email,
    presence: true,
    email: true

  validates :employee_id,
    presence: true

  validates :employee_personal_email,
    presence: true,
    email: true

  validates :employee_phone,
    presence: true

  validates :employee_name,
    presence: true

protected

  def submit
    RequestMailer.ucop_borrow_request_form_email(self).deliver_now
  end

end
