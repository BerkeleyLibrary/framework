class TindMarcBatchTestController < ApplicationController
  before_action :authorize!
  before_action :validate_params, only: :create

  def index
    redirect_with_params(action: :new)
  end

  def result; end

  # def create
  #   TindMarcBatchSecondJob.perform_later(TindMarcBatch.new(params).permitted_params, current_user.email)
  #   render :result
  # end
  def create
    creater = TindMarcSecondary::BatchCreator.new(TindMarcBatch.new(params).permitted_params, current_user.email)
    creater.run
    da_dir = Rails.application.config.tind_data_root_dir
    filename = File.join(da_dir, 'aerial/ucb/incoming/result.xml')
    creater.save_local(filename)
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
