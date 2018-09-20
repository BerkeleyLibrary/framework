class ScanRequestFormsController < ApplicationController
  before_action :authenticate!
  before_action :init_form!

  def index
    redirect_to new_scan_request_form_path
  end

  def new
    if not @scan_request.allowed?
      render :forbidden, status: :forbidden
    elsif @scan_request.blocked?
      render :blocked, status: :forbidden
    else
      render :new
    end
  end

  def create
    @scan_request.submit!

    if @scan_request.opted_in?
      redirect_to action: :show, id: :optin
    else
      redirect_to action: :show, id: :optout
    end
  rescue ActiveModel::ValidationError
    flash[:danger] ||= []
    @scan_request.errors.full_messages.each {|msg| flash[:danger] << msg}

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
    @scan_request = ScanRequestForm.new(
      opt_in: 'yes',
      patron_affiliation: @patron.affiliation,
      patron_blocks: @patron.blocks,
      patron_email: @patron.email,
      patron_employee_id: @patron.id,
      patron_name: @user.display_name,
      patron_type: @patron.type,
    )

    if not scan_params.blank?
      @scan_request.assign_attributes(scan_params)
      @scan_request.validate
    end
  end

  def scan_params
    params.require(:scan_request_form).permit(:opt_in, :patron_name)
  rescue ActionController::ParameterMissing
    {}
  end
end
