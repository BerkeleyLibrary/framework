class StudentEdevicesLoanFormsController < ApplicationController
  # First redirect the user to the CalNet login page
  before_action :authenticate!
  # Before loading the form, check that the user is a student
  before_action :init_form!

  def index
    redirect_to action: :new
  end

  def create
    @form.submit!
    redirect_to action: :show, id: :all_checked
  rescue ActiveModel::ValidationError => e
    Rails.logger.error(e)

    flash[:danger] ||= []
    @form.errors.full_messages.each { |msg| flash[:danger] << msg }
    redirect_with_params(action: :new)
  end

  def show
    if %w[blocked forbidden all_checked].include?(params[:id])
      render params[:id]
    else
      redirect_to action: :new
    end
  end

  private

  def init_form!
    @form = StudentEdevicesLoanForm.new(
      display_name: current_user.display_name,
      given_name: current_user.given_name,
      surname: current_user.surname,
      patron: current_user.primary_patron_record
    )
    @form.authorize!
    @form.validate unless @form.assign_attributes(form_params).blank?
  end

  # Make sure only specified attributes are allowed as params
  def form_params
    params.require(:student_edevices_loan_form).permit(
      :borrow_check,
      :edevices_check,
      :fines_check,
      :lending_check
    )
  rescue ActionController::ParameterMissing
    {}
  end
end
