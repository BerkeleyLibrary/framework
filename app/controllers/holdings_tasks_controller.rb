class HoldingsTasksController < ApplicationController

  # GET /holdings_tasks
  def index
    @holdings_tasks = HoldingsTask.all
  end

  # GET /holdings_tasks/1
  def show
    @holdings_task = HoldingsTask.find(params[:id])
  end

  # GET /holdings_tasks/new
  def new
    @holdings_task = HoldingsTask.new
  end

  # POST /holdings_tasks
  def create
    @holdings_task = HoldingsTask.create_from(**holdings_task_params)

    if @holdings_task.persisted?
      schedule_jobs(@holdings_task)
      redirect_to holdings_task_url(@holdings_task)
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def schedule_jobs(task)
    batch = GoodJob::Batch.add do
      Holdings::WorldCatJob.perform_later(task) if task.world_cat?
      Holdings::HathiTrustJob.perform_later(task) if task.hathi?
    end
    batch.enqueue(on_finish: Holdings::ResultsJob, task: task)
  end

  # TODO: handle missing parameters
  def holdings_task_params
    params.require(:holdings_task).tap do |pp|
      required_params = [:email, :input_file]
      required_params.each { |a| pp.require(a) }

      optional_params = [:rlf, :uc, :hathi]
      all_params = (required_params + optional_params)
      pp.permit(*all_params)
    end
  end

  def ensure_holdings_records(task)
    task.ensure_holdings_records!
  rescue StandardError => e
    logger.error("Error creating holdings records for task #{task.id}", e)

    task.errors.add(:input_file, e.message)
    raise ActiveModel::ValidationError(task)
  end
end
