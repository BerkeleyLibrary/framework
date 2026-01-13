class LocationRequestsController < ApplicationController
  before_action :ensure_user
  before_action :ensure_location_request, only: %i[show create result]
  before_action :require_framework_admin!, only: %i[immediate index]

  REQUIRED_PARAMS = %i[email input_file].freeze
  OPTIONAL_PARAMS = %i[slf uc hathi immediate].freeze
  ALL_PARAMS = (REQUIRED_PARAMS + OPTIONAL_PARAMS)

  # GET /location_requests
  def index
    @location_requests = LocationRequest.order(created_at: :desc)
  end

  # GET /location_requests/1
  def show
    @location_request = find_location_request
  end

  # GET /location_requests/new
  def new
    @location_request = LocationRequest.new(immediate: current_user.framework_admin?)
  end

  # GET /location_requests/immediate
  def immediate
    redirect_to new_location_request_url
  end

  # POST /location_requests
  def create
    if @location_request.persisted?
      schedule_batch_job
      flash[:success] = 'Location request scheduled.'
      redirect_to location_request_url(@location_request)
    else
      render :new, status: :unprocessable_entity
    end
  end

  # GET /location_requests/1/result
  def result
    output_file = @location_request.output_file
    if @location_request.incomplete? || !output_file.attached?
      render :not_found, status: :not_found
    else
      redirect_to rails_blob_path(output_file, disposition: 'attachment')
    end
  end

  private

  def schedule_batch_job
    # NOTE: We generate the result URL now in order to capture the
    # actual request hostname, rather than rely on the one hard-coded
    # in config.action_mailer.default_url_options
    result_url = location_requests_result_url(@location_request)
    Location::BatchJob.schedule(@location_request, result_url)
  end

  def ensure_user
    @user = current_user
  end

  def ensure_location_request
    @location_request ||= find_location_request || create_location_request
  end

  def find_location_request
    LocationRequest.find(id_param) if id_param
  end

  # params.require() is not smart enough to provide good error messages for multiple
  # missing parameters, so we do something a little more complicated here
  def create_location_request
    return LocationRequest.create_from(user: current_user, **location_request_opts) unless missing_params.any?

    # This will be invalid and fail to persist
    LocationRequest.create(**location_request_opts)
  end

  def id_param
    @id_param ||= params[:id]
  end

  def location_request_opts
    @location_request_opts ||= location_request_opts_from_params
  end

  def location_request_opts_from_params
    # ActionController::Parameters.to_h is not smart enough to take a block,
    # so we have to do this the hard way
    location_request_params = params.require(:location_request).permit(*ALL_PARAMS)
    location_request_params.to_h.symbolize_keys
  end

  def missing_params
    @missing_params ||= REQUIRED_PARAMS.reject do |k|
      v = location_request_opts[k]
      v.present? || v == false
    end
  end
end
