class DepartmentalCardForm < Form
  attr_accessor(
    :name,
    :email,
    :phone,
    :address,
    :supervisor_name,
    :supervisor_email,
    :barcode,
    :reason
  )

  validates :email, :supervisor_email,
            email: true,
            presence: true

  validates :name, :phone, :address, :supervisor_name, :reason, presence: true

  private

  def submit
    RequestMailer.departmental_card_form_email(self).deliver
  end

end
