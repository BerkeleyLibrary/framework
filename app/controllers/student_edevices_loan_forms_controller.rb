class StudentEdevicesLoanFormsController < ApplicationController
  # class ForbiddenError < StandardError; end

  before_action :authenticate!
  before_action :init_form!
 #before_action :authorize!

  # rescue_from ForbiddenError do |e|
  #   render :forbidden, status: :forbidden
  # end

  # private

  def authorize!
    patron = current_user.student_patron_record

    raise ForbiddenError, "Missing Patron record" if patron.nil?
    raise ForbiddenError, "Patron has manual blocks" if not patron.blocks.nil?
  end

  #Before loading the form, check that the user is library staff. If not, display a you cannot enter message

  def index
    redirect_to action: :new
  end

  def create
    @form.submit!
    redirect_to action: :show, id: :all_checked
  rescue ActiveModel::ValidationError => e
    Rails.logger.error(e)

    flash[:danger] ||= []
    @form.errors.full_messages.each{|msg| flash[:danger] << msg}
    redirect_with_params(action: :new)
  end

  def show
    if %w(blocked forbidden all_checked).include?(params[:id])
      render params[:id]
    else
      redirect_to action: :new
    end
  end

private

  def init_form!
    #Rails.logger.debug{"here?!!!!     "}
    #Rails.logger.debug(current_user.to_json)
    @form = StudentEdevicesLoanForm.new(
      display_name: current_user.display_name,
      patron: current_user.employee_patron_record || current_user.student_patron_record,
    )
    @form.authorize!
    @form.tellme
    @form.validate unless @form.assign_attributes(form_params).blank?
  end

  # Make sure only specified attributes are allowed as params
  def form_params
    params.require(:student_edevices_loan_form).permit(
      :borrow_check,
      :edev_check,
      :fines_check,
      :lend_check,
    )
  rescue ActionController::ParameterMissing
    {}
  end
end

