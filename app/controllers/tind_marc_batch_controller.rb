class TindMarcBatchController < ApplicationController
  before_action :authorize!, only: :index
  before_action :validate_params, only: :batch

  def index
    @current_user = current_user
  end

  def result; end

  def batch
    TindMarcBatchJob.perform_later(TindMarcBatch.new(params).permitted_params)
    render :result
  end

  private

  def validate_params
    validator = TindMarcBatch.new(params)
    redirect_to(action: :index) unless validator.valid?
  end

  def authorize!
    authenticate!
    raise Error::ForbiddenError unless current_user.alma_admin
  end

end
