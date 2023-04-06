class HoldingsTasksController < ApplicationController
  before_action :ensure_holdings_task, only: %i[show create result]

  REQUIRED_PARAMS = %i[email input_file].freeze
  OPTIONAL_PARAMS = %i[rlf uc hathi].freeze
  ALL_PARAMS = (REQUIRED_PARAMS + OPTIONAL_PARAMS)

  # GET /holdings_tasks
  def index
    @holdings_tasks = HoldingsTask.all
  end

  # GET /holdings_tasks/1
  def show
    @holdings_task = find_holdings_task
  end

  # GET /holdings_tasks/new
  def new
    @holdings_task = HoldingsTask.new
  end

  # POST /holdings_tasks
  def create
    if @holdings_task.persisted?
      schedule_jobs(@holdings_task)
      redirect_to holdings_task_url(@holdings_task)
    else
      render :new, status: :unprocessable_entity
    end
  end

  # GET /holdings_tasks/1/result
  def result
    output_file = @holdings_task.output_file
    if @holdings_task.incomplete? || !output_file.attached?
      render :not_found, status: :not_found
    else
      redirect_to rails_blob_path(output_file, disposition: 'attachment')
    end
  end

  private

  def ensure_holdings_task
    @holdings_task ||= (find_holdings_task || create_holdings_task)
  end

  def find_holdings_task
    HoldingsTask.find(id_param) if id_param
  end

  # params.require() is not smart enough to provide good error messages for multiple
  # missing parameters, so we do something a little more complicated here
  def create_holdings_task
    return HoldingsTask.create_from(**holdings_task_opts) unless missing_params.any?

    # This will be invalid and fail to persist
    HoldingsTask.create(**holdings_task_opts)
  end

  def id_param
    @id_param ||= params[:id]
  end

  def schedule_jobs(task)
    # TODO: make these run off-hours (wrapper job?)
    #       see https://github.com/bensheldon/good_job/blob/main/README.md#complex-batches
    #       see https://github.com/bensheldon/good_job/blob/main/README.md#cron-style-repeatingrecurring-jobs
    GoodJob::Batch.enqueue(on_finish: Holdings::ResultsJob, task:) do
      Holdings::WorldCatJob.perform_later(task) if task.world_cat?
      Holdings::HathiTrustJob.perform_later(task) if task.hathi?
    end
  end

  def holdings_task_opts
    # ActionController::Parameters.to_h is not smart enough to take a block, so we have
    # to do this the hard way
    @holdings_task_opts ||= params.require(:holdings_task).permit(*ALL_PARAMS).to_h.symbolize_keys
  end

  def missing_params
    @missing_params ||= REQUIRED_PARAMS.reject do |k|
      v = holdings_task_opts[k]
      v.present? || v == false
    end
  end
end
