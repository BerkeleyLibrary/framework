class ServiceArticleRequestFormsController < ApplicationController
  #First redirect the user to the CalNet login page
  before_action :authenticate!

  #Before loading the form, check for eligibility for the article scan request service
  before_action :init_form!

  def index
    redirect_to action: :new
  end

  def new
    #Check to confirm eligibility for the article request service, which is more complicated than a yes/no validation
    if @form.eligible_note?
      render :new
    elsif @form.faculty?
      if not @form.eligible_note?
        render :required, status: :forbidden
      end
    elsif @form.student?
      if not @form.eligible_note?
        render :student, status: :forbidden
      end
    else
      render :ineligible, status: :forbidden
    end
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
    if %w(ineligible confirmed).include?(params[:id])
      render params[:id]
    else
      redirect_to action: :new
    end
  end

private

  def init_form!
    #Instantiate new form object
    @form = ServiceArticleRequestForm.new(
      display_name: current_user.display_name,
      patron: current_user.employee_patron_record || current_user.student_patron_record
    )
    #Run through all the form validators for the strict validations
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
