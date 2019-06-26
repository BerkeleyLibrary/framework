class ServiceArticleRequestFormsController < ApplicationController
  #First redirect the user to the CalNet login page
  before_action :authenticate!

  #Before loading the form, check for eligibility for the article scan request service
  before_action :init_form!

  self.support_email = 'baker@library.berkeley.edu'

  def index
    redirect_to action: :new
  end

  def create
    @form.submit!
    redirect_to action: :show, id: :confirmed
  rescue ActiveModel::ValidationError => e
    Rails.logger.error(e)

    flash[:danger] ||= []
    @form.errors.full_messages.each{|msg| flash[:danger] << msg}
    redirect_with_params(action: :new)
  end

  def show
    if %w(ineligible confirmed forbidden required student).include?(params[:id])
      render params[:id]
    else
      redirect_to action: :new
    end
  end

private

  def init_form!
    @form = ServiceArticleRequestForm.new(
      display_name: current_user.display_name,
      patron: current_user.primary_patron_record
    )
    @form.authorize!
    @form.validate unless @form.assign_attributes(form_params).blank?
  end

  # Make sure only specified attributes are allowed as params
  def form_params
    params.require(:service_article_request_form).permit(
      :display_name,
      :patron_email,
      :pub_title,
      :pub_location,
      :issn,
      :vol,
      :article_title,
      :author,
      :pages,
      :citation,
      :pub_notes
    )
  rescue ActionController::ParameterMissing
    {}
  end
end
