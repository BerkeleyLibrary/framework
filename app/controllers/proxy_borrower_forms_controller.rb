require 'time'

# class ProxyBorrowerFormsController < ApplicationController
class ProxyBorrowerFormsController < AuthenticatedFormController
  before_action :set_current_user, only: %i[dsp_form faculty_form process_dsp_request process_faculty_request]

  # Simple page where you can select which form you wish to access
  def index
    # I think I want to get the users role now... if they're in the DB
    # then I'll want to pass that info so they have the
    # admin link...otherwise, NO admin link!
    @user_is_admin = current_user.role?(Role.proxyborrow_admin)
  end

  def dsp_form
    # wisks us away to Disabled Student Program Form (views/proxy_borrower_forms/dsp_form)
    @form = ProxyBorrowerRequests.new(student_name: @current_user.display_name)
  end

  def faculty_form
    # wisks us away to Faculty Form
    render :forbidden, status: :forbidden and return unless current_user.ucb_faculty?

    @form = ProxyBorrowerRequests.new(faculty_name: @current_user.display_name,
                                      department: @current_user.department_number)
  end

  # TODO: do we still need this?
  def forbidden; end

  # Processes a request from DSP form: (eventually dry this up)
  def process_dsp_request
    @form = ProxyBorrowerRequests.new form_params(:student_name, :dsp_rep)
    @form.student_dsp = current_user.ucpath_id
    @form.user_email = current_user.email

    if @form.save
      # Sends an email to the user with instructions:
      @form.submit!
      render 'result', status: :created
    else
      render 'dsp_form', status: :unprocessable_entity
    end
  end

  # Processes a request from faculty form:
  def process_faculty_request
    @form = ProxyBorrowerRequests.new form_params(:faculty_name, :department)
    @form.faculty_id = current_user.ucpath_id
    @form.user_email = current_user.email

    if @form.save
      # Sends an email to the user with instructions:
      @form.submit!
      render 'result', status: :created
    else
      # Failed to save - rerender the faculty form:
      render 'faculty_form', status: :unprocessable_entity
    end
  end

  def result
    # Hunkydory, we saved a request to the DB, let's let the user know!
  end

  private

  def init_form!; end

  def set_current_user
    @current_user = current_user
  end

  def form_params(*extra)
    params.require(:proxy_borrower_requests).permit(:research_last, :research_first, :research_middle,
                                                    :date_term, :renewal, *extra)
  end
end
