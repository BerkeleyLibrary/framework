class DepartmentalCardFormsController < ApplicationController
  before_action :authorize!, :init_form!
  ALLOWED_PARAMS = %i[name address email phone supervisor_name supervisor_email barcode reason].freeze

  self.support_email = 'privdesk-library@berkeley.edu'

  def new
    @display_name = current_user.display_name
    @email = current_user.email
  end

  def index
    redirect_to action: :new
  end

  def create
    process_params(params)

    @form.submit!
    render :result
  rescue ActiveModel::ValidationError
    flash[:danger] = @form.errors.to_a
    redirect_with_params action: :new
  end

  private

  def process_params(params)
    ALLOWED_PARAMS.each do |param|
      @form.send("#{param}=", params[param])
    end
  end

  def authorize!
    authenticate!
  end

  def init_form!
    @form = DepartmentalCardForm.new(
      name: current_user.display_name,
      email: current_user.email
    )

    return if form_params.empty?

    @form.attributes = form_params

    @form.validate
  end

  # Make sure only specified attributes are allowed as params
  def form_params
    params.require(:departmental_card_form).permit(:name, :address, :phone, :email, :supervisor_name, :supervisor_email, :barcode, :reason)
  rescue ActionController::ParameterMissing
    {}
  end

end
