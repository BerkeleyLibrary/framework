class MmsidTindController < ApplicationController
  before_action :authorize!
  before_action :validate_params, only: :create

  def result; end

  def create
    MmsidTindJob.perform_later(MmsidTind.new(params).permitted_params, current_user.email)
    render :result
  end

  # testing locally
  # def create
  #   creater = TindMarc::MmsidTindTask.new(MmsidTind.new(params).permitted_params, current_user.email)
  #   creater.run
  #   render :result
  # end

  private

  def validate_params
    validator = MmsidTind.new(params)
    handle_validation_errors(validator) unless validator.valid?
  end

  def handle_validation_errors(validator)
    msg = validator.errors.full_messages.join(',')
    flash[:danger] = msg
    redirect_to(action: :new)
  end

  def authorize!
    authenticate!

    # TODO: Unify Framework user roles, these sorts of checks
    roles = %i[alma_admin?]
    raise Error::ForbiddenError unless roles.any? { |role| current_user.send(role) }
  end

end
