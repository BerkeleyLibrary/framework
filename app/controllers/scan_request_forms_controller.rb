class ScanRequestFormsController < ApplicationController
  before_action :authenticate!
  before_action :init_form!

  self.support_email = 'prntscan@lists.berkeley.edu'

  def index
    redirect_with_params(action: :new)
  end

  def new
    if not @form.allowed?
      render :forbidden, status: :forbidden
    elsif @form.blocked?
      render :blocked, status: :forbidden
    else
      render :new
    end
  end

  def create
    @form.submit!

    if @form.opted_in?
      redirect_to action: :show, id: :optin
    else
      redirect_to action: :show, id: :optout
    end
  rescue ActiveModel::ValidationError
    flash[:danger] ||= []
    @form.errors.full_messages.each {|msg| flash[:danger] << msg}

    redirect_with_params(action: :new)
  end

  def show
    if %w(blocked forbidden optin optout).include?(params[:id])
      render params[:id]
    else
      redirect_with_params(action: :new)
    end
  end

  private

  def init_form!
    logger.info(session[:user])

    @form = ScanRequestForm.new(
      patron: current_user.employee_patron_record || current_user.student_patron_record,
      patron_name: current_user.display_name,
    )

    @form.validate unless @form.assign_attributes(form_params).blank?
  end

  def form_params
    params.require(:scan_request_form).permit(:opt_in, :patron_name)
  rescue ActionController::ParameterMissing
    {}
  end
end
