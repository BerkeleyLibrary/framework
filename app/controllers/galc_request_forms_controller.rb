class GalcRequestFormsController < ApplicationController
  #First redirect the user to the CalNet login page
  before_action :authenticate!

  #Before loading the form, check for GALC eligibility
  before_action :init_form!

  self.support_email = 'webman@library.berkeley.edu'

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
    #Instantiate new form object
    @form = GalcRequestForm.new(
      display_name: current_user.display_name,
      patron: current_user.employee_patron_record || current_user.student_patron_record
    )
    #Run through all the form validators for the strict validations
    @form.authorize!
    #Specifically check the Millenium patron account for eligibility note and render view associated with eligibility and patron type
    begin
      @form.note_validate!
    rescue Error::FacultyNoteError => e
      render :required, status: :forbidden
    rescue Error::StudentNoteError => e
      render :student, status: :forbidden
    rescue Error::GeneralNoteError => e
      render :ineligible, status: :forbidden
    end
    @form.validate unless @form.assign_attributes(form_params).blank?
  end

  # Make sure only specified attributes are allowed as params
  def form_params
    params.require(:galc_request_form).permit(
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

