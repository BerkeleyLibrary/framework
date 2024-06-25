class DoemoffPatronEmailFormsController < ApplicationController
  before_action :authorize!, :init_form!

  def index
    redirect_to action: :new
  end

  def create
    @form.submit!
    render :result
  rescue ActiveModel::ValidationError
    flash[:danger] = @form.errors.to_a
    redirect_with_params(action: :new)
  end

  private

  def form_params
    params.require(:doemoff_patron_email_form).permit!
  rescue ActionController::ParameterMissing
    {}
  end

  def authorize!
    authenticate!
  end

  def init_form!
    @form = DoemoffPatronEmailForm.new
    return if form_params.empty?

    @form.attributes = form_params
    @form.validate
    @form.recipient_email = form_params[:sender]
  end

end
