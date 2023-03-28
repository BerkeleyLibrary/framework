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
    @holdings_task = HoldingsTask.create(holdings_task_params)
    ensure_holdings_records(@holdings_task)

    # TODO: schedule job(s)

    redirect_to holdings_task_url(@holdings_task), notice: 'Holdings task was successfully created.'
  rescue ActiveModel::ValidationError => e
    # TODO: Figure out how to validate input_file attachment before committing
    @holdings_task.delete if @holdings_task.persisted?

    logger.warn('Error creating holdings task', e)
    render :new, status: :unprocessable_entity
  end

  private

  def holdings_task_params
    params.require(:holdings_task).permit(:email, :rlf, :uc, :hathi, :input_file)
  end

  def ensure_holdings_records(task)
    task.ensure_holdings_records!
  rescue StandardError => e
    logger.error("Error creating holdings records for task #{task.id}", e)

    task.errors.add(:input_file, e.message)
    raise ActiveModel::ValidationError(task)
  end
end
