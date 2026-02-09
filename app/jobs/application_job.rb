class ApplicationJob < ActiveJob::Base
  attr_reader :request_id

  before_enqueue do
    self.arguments << { request_id: Current.request_id }
  end

  around_perform do |job, block|
    @request_id = job.arguments.pop[:request_id] || ''
    block.call
  end

  around_perform :log_activejob_id

  def today
    @today ||= Time.zone.now.strftime('%Y%m%d')
  end

  # AP-186: Add the ActiveJob ID to job logs
  def log_activejob_id
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
