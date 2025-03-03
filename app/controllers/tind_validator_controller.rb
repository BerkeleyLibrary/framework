class TindValidatorController < ApplicationController
  before_action :authorize!
  before_action :validate_params, only: :create

  def create
    attach = TindValidator.create!(params)
    attach.input_file.attach(params[:input_file])
    TindValidatorJob.perform_later(TindValidator.new(params).permitted_params, attach, current_user.email)
    render :result
  end

  def result; end

  private

  def validate_params
    validator = TindValidator.new(params)
    handle_validation_errors(validator) unless validator.valid?
  end

  def handle_validation_errors(validator)
    msg = validator.errors.full_messages.join(',')
    flash[:danger] = msg
    redirect_with_params(action: :new)
  end

  def authorize!
    authenticate!
    # raise Error::ForbiddenError unless current_user.alma_admin
  end
end
