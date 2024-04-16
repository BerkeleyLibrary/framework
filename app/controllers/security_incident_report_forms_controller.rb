class SecurityIncidentReportFormsController < ApplicationController
  before_action :authorize!, :init_form!

  def new
    @user_email = current_user.email
  end

  def index
    redirect_with_params(action: :new)
  end

  def create
    @form.submit!
    render :result
  rescue ActiveModel::ValidationError
    flash[:danger] = @form.errors.to_a
    redirect_to action: :new
  end

  private

  def form_params
    params.require(:security_incident_report_form).permit!
  rescue ActionController::ParameterMissing
    {}
  end

  def authorize!
    authenticate!
  end

  def init_form!
    @form = SecurityIncidentReportForm.new
    return if form_params.empty?

    @form.attributes = form_params
    @form.validate
  end

end
