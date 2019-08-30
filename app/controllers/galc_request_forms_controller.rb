class GalcRequestFormsController < ApplicationController
  # First redirect the user to the CalNet login page
  before_action :authenticate!

  # Before loading the form, check for GALC eligibility
  before_action :init_form!

  self.support_email = 'webman@library.berkeley.edu'

  def index
    redirect_to action: :new
  end

  def create
    @form.submit!
    redirect_to action: :show, id: :confirmed
  rescue ActiveModel::ValidationError => e
    Rails.logger.error(e)

    flash[:danger] ||= []
    @form.errors.full_messages.each { |msg| flash[:danger] << msg }
    redirect_with_params(action: :new)
  end

  def show
    if %w[confirmed forbidden].include?(params[:id])
      render params[:id]
    else
      redirect_to action: :new
    end
  end

  private

  def init_form!
    # Instantiate new form object
    @form = GalcRequestForm.new(patron: current_user.primary_patron_record)
    # Run through all the form validators for the strict validations
    @form.authorize!
    @form.validate unless @form.assign_attributes(form_params).blank?
  end

  # Make sure only specified attributes are allowed as params
  def form_params
    params.require(:galc_request_form).permit(
      :patron_email,
      :borrow_check,
      :fine_check
    )
  rescue ActionController::ParameterMissing
    {}
  end
end
