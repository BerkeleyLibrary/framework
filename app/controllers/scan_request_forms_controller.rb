class ScanRequestFormsController < ApplicationController
  before_action :authenticate!
  before_action :init_form!

  def index
    redirect_to new_scan_request_form_path
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

    redirect_to new_scan_request_form_path(request.parameters)
  end

  def show
    if %w(blocked forbidden optin optout).include?(params[:id])
      render params[:id]
    else
      redirect_to new_scan_request_form_path
    end
  end

  private

  def init_form!
    logger.info(session[:user])

    @user = User.new(session[:user])
    @patron = @user.patron
    @form = ScanRequestForm.new(
      opt_in: 'yes',
      patron_affiliation: @patron.affiliation,
      patron_blocks: @patron.blocks,
      patron_email: @patron.email,
      patron_employee_id: @patron.id,
      patron_name: @user.display_name,
      patron_type: @patron.type,
    )

    if not scan_params.blank?
      @form.assign_attributes(scan_params)
      @form.validate
    end
  end

  def scan_params
    params.require(:scan_request_form).permit(:opt_in, :patron_name)
  rescue ActionController::ParameterMissing
    {}
  end
end
