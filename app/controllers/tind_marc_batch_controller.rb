class TindMarcBatchController < ApplicationController
  before_action :authorize!, only: :index
  before_action :validate_params, only: :batch

  def index; end

  def result; end

  def batch
    TindMarcBatchJob.perform_later(TindMarcBatch.new(params).permitted_params)
    render :result
  end

  private

  def validate_params
    params[:email] = current_user.email
    
    # Not sure these are always in Calnet. Will be used for initials in batch load
    params[:initials] = current_user.given_name[0] + current_user.surname[0]
    validator = TindMarcBatch.new(params)

    render :index unless validator.valid?
  end

  def authorize!
    authenticate!
    raise Error::ForbiddenError unless current_user.alma_admin
  end

end
