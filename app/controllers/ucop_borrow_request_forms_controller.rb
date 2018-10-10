class UcopBorrowRequestFormsController < ApplicationController
  before_action :init_form!
  before_action :validate_recaptcha!, only: [:create]

  def index
    redirect_to new_ucop_borrow_request_form_path and return
  end

  def create
    @form.submit!

    flash[:success] = t('.success', department_head_email: @form.department_head_email)
    redirect_to new_ucop_borrow_request_form_path and return
  rescue Recaptcha::VerifyError
    flash[:danger] = t('.recaptcha')
    redirect_to_new and return
  rescue ActiveModel::ValidationError
    redirect_to_new and return
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
      @form.attributes = borrow_request_params
      @form.validate
    end
  end

  def validate_recaptcha!
    verify_recaptcha!(model: @form)
  end

  def redirect_to_new
    redirect_to new_ucop_borrow_request_form_path(request.parameters)
  end
end
