class UcopBorrowRequestFormsController < ApplicationController
  def index
    redirect_to new_ucop_borrow_request_form_path
  end

  def new
    @borrow_request = UcopBorrowRequestForm.new

    if not borrow_request_params.empty?
      @borrow_request.assign_attributes(borrow_request_params)
      @borrow_request.validate
    end
  end

  def create
    @borrow_request = UcopBorrowRequestForm.new(borrow_request_params)
    @borrow_request.submit!

    flash_message(@borrow_request)
    redirect_to new_ucop_borrow_request_form_path
  rescue ActiveModel::ValidationError
    redirect_to new_ucop_borrow_request_form_path(request.parameters)
  end

  private

  def borrow_request_params
    params.require(:ucop_borrow_request_form).permit!
  rescue ActionController::ParameterMissing
    {}
  end

  def flash_message(borrow_request)
    if borrow_request.valid?
      flash[:success] = t('.success',
        department_head_email: @borrow_request.department_head_email,
      )
    end
  end
end
