# app/models/affiliate_borrow_request_form.rb
class AffiliateBorrowRequestForm < Form
  ATTRIBUTES = %i[
    department_head_email
    department_head_name
    department_name
    employee_email
    employee_id
    employee_name
    employee_personal_email
    employee_phone
    employee_preferred_name
    employee_address
  ].freeze

  BorrowRequest = Struct.new(*ATTRIBUTES, keyword_init: true)

  attr_accessor(*ATTRIBUTES)

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

  validates :employee_address,
            presence: true

  # Return a serializable hash for deliver_later
  def to_h
    ATTRIBUTES.index_with { |attr| public_send(attr) }
  end

  def submit!
    raise ActiveModel::ValidationError, self unless valid?

    RequestMailer.affiliate_borrow_request_form_email(to_h).deliver_later
  end
end
