class ApplicationJob < ActiveJob::Base
  attr_reader :request_id

  before_enqueue do
    arguments << { request_id: Current.request_id } if Current.request_id
  end

  around_perform do |job, block|
    @request_id = job.arguments.pop[:request_id] if job.arguments.last.is_a?(Hash) && job.arguments.last.key?(:request_id)
    block.call
  end

  around_perform :log_job_metadata

  def today
    @today ||= Time.zone.now.strftime('%Y%m%d')
  end

  def log_job_metadata
    logger.with_fields = { activejob_id: job_id, request_id: @request_id }
    yield
  end

  # Log an exception
  def log_error(error)
    # TODO: share code w/ApplicationController
    msg = {
      msg: error.message,
      error: error.inspect,
      cause: error.cause.inspect
    }
    msg[:backtrace] = error.backtrace if Rails.logger.level < Logger::INFO
    logger.error(msg)
  end
end
