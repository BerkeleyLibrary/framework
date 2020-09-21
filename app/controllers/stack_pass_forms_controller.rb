require 'time'

class StackPassFormsController < ApplicationController
  rescue_from ActiveRecord::RecordNotFound, with: :render_404
  before_action :init_form!

  def render_404
    render template: 'errors/error_404', status: 404
  end

  def forbidden; end

  def index
    # redirect_with_params(action: :new)
    user_role = FrameworkUsers.role?(current_user.uid, 'stackpass_admin')
    @user_role = if user_role.blank?
                   nil
                 else
                   user_role
                 end
  end

  def result; end

  # Show an admin the request
  def show
    admin?
    # TODO : If no find....then tell user you couldn't find it!
    @current_user = current_user
    @req = StackPassForm.find(params[:id])

    @approvals = @req.approval_count
    @denials = @req.denial_count
  end

  # Approve || Deny Request
  # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
  def update
    admin?

    @form = StackPassForm.find(params[:id])

    @form.approved = params[:stack_pass_][:approve_deny]
    @form.approved_by = params[:approved_by]

    if @form.approved == false
      @form.denial_reason = params[:denial_reason]
      @form.deny!
    else
      @form.approve!
    end

    @form.save

    flash[:success] = 'Request has been successfully processed'
    redirect_with_params(action: :show)
  end
  # rubocop:enable Metrics/MethodLength, Metrics/AbcSize

  # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
  def create
    validate_recaptcha!

    # Need to gab and convert the date:
    @form.pass_date = convert_date_param unless params[:stack_pass_form][:pass_date].blank?

    if @form.save
      @form.submit!
      render 'result', status: 201
    else
      flash[:danger] = "Error : #{@form.errors.messages}"
      redirect_with_params(action: :new)
    end
  rescue Recaptcha::RecaptchaError
    flash[:danger] = t('.recaptcha')
    redirect_with_params(action: :new)
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

  def admin?
    if FrameworkUsers.role?(current_user.uid, 'stackpass_admin')
      @user_role = 'Admin'
    else
      render 'forbidden', status: 201
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

end
