class TindMarcBatchController < ApplicationController
  before_action :authorize!
  before_action :validate_params, only: :create

  def new
    @current_user = current_user
  end

  def index
    redirect_with_params(action: :new)
  end

  def result; end

  def create
    TindMarcBatchJob.perform_later(TindMarcBatch.new(params).permitted_params)
    render :result
  end

  private

  def validate_params
    validator = TindMarcBatch.new(params)
    handle_validation_errors(validator) unless validator.valid?
  end

  def handle_validation_errors(validator)
    msg = validator.errors.full_messages.join(',')
    flash[:danger] = msg
    redirect_to(action: :new)
  end

  def authorize!
    authenticate!
    raise Error::ForbiddenError unless current_user.alma_admin
  end

end
