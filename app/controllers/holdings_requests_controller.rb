class HoldingsRequestsController < ApplicationController
  before_action :ensure_holdings_request, only: %i[show create result]

  REQUIRED_PARAMS = %i[email input_file].freeze
  OPTIONAL_PARAMS = %i[rlf uc hathi].freeze
  ALL_PARAMS = (REQUIRED_PARAMS + OPTIONAL_PARAMS)

  # GET /holdings_requests
  def index
    @holdings_requests = HoldingsRequest.all
  end

  # GET /holdings_requests/1
  def show
    @holdings_request = find_holdings_request
  end

  # GET /holdings_requests/new
  def new
    @holdings_request = HoldingsRequest.new
  end

  # POST /holdings_requests
  def create
    if @holdings_request.persisted?
      Holdings::JobScheduler.schedule_jobs(@holdings_request)
      redirect_to holdings_request_url(@holdings_request)
    else
      render :new, status: :unprocessable_entity
    end
  end

  # GET /holdings_requests/1/result
  def result
    output_file = @holdings_request.output_file
    if @holdings_request.incomplete? || !output_file.attached?
      render :not_found, status: :not_found
    else
      redirect_to rails_blob_path(output_file, disposition: 'attachment')
    end
  end

  private

  def ensure_holdings_request
    @holdings_request ||= (find_holdings_request || create_holdings_request)
  end

  def find_holdings_request
    HoldingsRequest.find(id_param) if id_param
  end

  # params.require() is not smart enough to provide good error messages for multiple
  # missing parameters, so we do something a little more complicated here
  def create_holdings_request
    return HoldingsRequest.create_from(**holdings_request_opts) unless missing_params.any?

    # This will be invalid and fail to persist
    HoldingsRequest.create(**holdings_request_opts)
  end

  def id_param
    @id_param ||= params[:id]
  end

  def holdings_request_opts
    # ActionController::Parameters.to_h is not smart enough to take a block, so we have
    # to do this the hard way
    @holdings_request_opts ||= params.require(:holdings_request).permit(*ALL_PARAMS).to_h.symbolize_keys
  end

  def missing_params
    @missing_params ||= REQUIRED_PARAMS.reject do |k|
      v = holdings_request_opts[k]
      v.present? || v == false
    end
  end
end
