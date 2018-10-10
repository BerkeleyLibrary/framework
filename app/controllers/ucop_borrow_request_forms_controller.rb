class UcopBorrowRequestFormsController < ApplicationController
  def index
    redirect_to new_ucop_borrow_request_form_path
  end

  def new
    init_form!
  end

  def create
    init_form!
    verify_recaptcha!(model: @form)
    @form.submit!

    flash[:success] = t('.success', department_head_email: @form.department_head_email)
    redirect_to new_ucop_borrow_request_form_path
  rescue Recaptcha::VerifyError
    flash[:danger] = t('.recaptcha')
    redirect_to_new
  rescue ActiveModel::ValidationError
    redirect_to_new
  end

  private

  def borrow_request_params
    params.require(:ucop_borrow_request_form).permit!
  rescue ActionController::ParameterMissing
    {}
  end

  def init_form!
    @form = UcopBorrowRequestForm.new

    if not borrow_request_params.empty?
      @form.assign_attributes(borrow_request_params)
      @form.validate
    end
  end

  def redirect_to_new
    redirect_to new_ucop_borrow_request_form_path(request.parameters)
  end
end
