require 'time'

# class ProxyBorrowerFormsController < ApplicationController
class ProxyBorrowerFormsController < AuthenticatedFormController
  # Simple page where you can select which form you wish to access
  def index
    # I think I want to get the users role now... if they're in the DB
    # then I'll want to pass that info so they have the
    # admin link...otherwise, NO admin link!
    @user_is_admin = current_user.role?(Role.proxyborrow_admin)
  end

  def dsp_form
    # wisks us away to Disabled Student Program Form (views/proxy_borrower_forms/dsp_form)
    @request_form = ProxyBorrowerRequests.new
    @current_user = current_user
  end

  def faculty_form
    # wisks us away to Faculty Form
    if faculty?
      @request_form = ProxyBorrowerRequests.new
      @current_user = current_user
    else
      redirect_to forms_proxy_borrower_forbidden_path
    end
  end

  # TODO: do we still need this?
  def forbidden; end

  # Processes a request from DSP form: (eventually dry this up)
  def process_dsp_request
    @request_form = process_params(params)

    if @request_form.save
      # Sends an email to the user with instructions:
      @request_form.submit!
      render 'result', status: 201
    else
      @current_user = current_user
      render 'dsp_form'
    end
  end

  # Processes a request from faculty form:
  def process_faculty_request
    @request_form = process_params(params)

    if @request_form.save
      # Sends an email to the user with instructions:
      @request_form.submit!
      render 'result', status: 201
    else
      # Failed to save - rerender the faculty form:
      @current_user = current_user
      render 'faculty_form'
    end
  end

  def result
    # Hunkydory, we saved a request to the DB, let's let the user know!
  end

  private

  # Not sure if I need additional affiliations here or not...
  def faculty?
    @faculty ||= current_user.affiliations&.include?('EMPLOYEE-TYPE-ACADEMIC')
  end

  def init_form!; end

  # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity, Metrics/MethodLength, Metrics/AbcSize
  def process_params(params)
    request = ProxyBorrowerRequests.new
    request['faculty_name'] = params['faculty_name'] || nil
    request['department'] = params['department'] || nil
    request['faculty_id'] = params['faculty_id'] || nil
    request['user_email'] = params['user_email'] || nil
    request['student_name'] = params['student_name'] || nil
    request['student_dsp'] = params['student_dsp'] || nil
    request['research_last'] = params['research_last'] || nil
    request['research_first'] = params['research_first'] || nil
    request['research_middle'] = params['research_middle'] || nil
    request['dsp_rep'] = params['dsp_rep'] || nil
    request['renewal'] = params['renewal'].to_i

    # Handle the Proxy Term (date the term ends):
    if params['term'].blank?
      # If term is blank - set to nil:
      request['date_term'] = nil
    else
      if (date_param = params['term'].match(%r{^(\d+/\d+/)(\d{2})$}))
        params['term'] = date_param[1] + '20' + date_param[2]
      end

      begin
        # Try to convert the string date to a date obj:
        request['date_term'] = Date.strptime(params['term'], '%m/%d/%Y')
      rescue ArgumentError
        # If bad argument set to nil:
        request['date_term'] = nil
      end
    end
    request
  end
  # rubocop:enable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity, Metrics/MethodLength, Metrics/AbcSize

end
