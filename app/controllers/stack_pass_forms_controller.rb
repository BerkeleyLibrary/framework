require 'time'

class StackPassFormsController < ApplicationController
  before_action :init_form!

  def index
    redirect_with_params(action: :new)
  end

  # TODO: do we still need this?
  def forbidden; end

  def result; end

  # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
  def create
    validate_recaptcha!

    # Need to gab and convert the date:
    unless params[:stack_pass_form][:pass_date].blank?
      @form.pass_date = (convert_date_param if params[:stack_pass_form][:pass_date].split('/').length == 3)
    end

    if @form.save
      @form.submit!
      render 'result', status: 201
    else
      flash[:danger] = @form.errors.to_a
      redirect_with_params(action: :new)
    end
  rescue Recaptcha::RecaptchaError
    flash[:danger] = t('.recaptcha')
    redirect_with_params(action: :new)
  end
  # rubocop:enable Metrics/MethodLength, Metrics/AbcSize

  # Show an admin the request
  def show
    require_admin!
    @current_user = current_user
    @req = StackPassForm.find(params[:id])

    @approvals = @req.approval_count
    @denials = @req.denial_count
  end

  # Approve || Deny Request
  # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
  def update
    require_admin!

    @form = StackPassForm.find(params[:id])
    @form.approvedeny = params[:stack_pass_][:approve_deny]
    @form.processed_by = params[:processed_by]

    if @form.approvedeny == false
      deny_reason = params[:denial_reason]
      deny_reason = params[:stack_pass_denial][:denial_reason] if deny_reason.empty?
      @form.denial_reason = deny_reason
      @form.deny!
    else
      @form.approve!
    end

    @form.save!
    flash[:success] = 'Request has been successfully processed'
    redirect_to(action: :show, id: params[:id])
  end
  # rubocop:enable Metrics/MethodLength, Metrics/AbcSize

  private

  def convert_date_param
    # Try to handle mm/dd/yy:
    if (date_param = params[:stack_pass_form][:pass_date].match(%r{^(\d+/\d+/)(\d{2})$}))
      params[:stack_pass_form][:pass_date] = date_param[1] + '20' + date_param[2]
    end

    begin
      # Try to convert the string date to a date obj:
      Date.strptime(params[:stack_pass_form][:pass_date], '%m/%d/%Y')
    rescue ArgumentError
      # If bad argument set to nil:
    end
  end

  def form_params
    params.require(:stack_pass_form).permit(:name, :email, :phone, :local_id, :main_stack, :pass_date)
  rescue ActionController::ParameterMissing
    {}
  end

  def init_form!
    @form = StackPassForm.new
    return if form_params.empty?

    @form.attributes = form_params
    @form.validate
  end

  def validate_recaptcha!
    verify_recaptcha!(model: @form)
  end

  def require_admin!
    if FrameworkUsers.role?(current_user.uid, Role.stackpass_admin)
      @user_role = 'Admin'
    else
      # If we want a forbidden page:
      # render 'forbidden', status: 201

      # Else we can go to the login page:
      redirect_to login_path(url: request.fullpath)
    end
  end
end
