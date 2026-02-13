class ApplicationJob < ActiveJob::Base
  before_enqueue do
    arguments << { request_id: Current.request_id } if Current.request_id
  end

  before_perform :log_job_metadata

  def request_id
    if !defined? @request_id
      if arguments.last.is_a?(Hash) && arguments.last.key?(:request_id)
        @request_id = arguments.pop[:request_id]
      else
        @request_id = nil
      end
    end
    @request_id
  end

  def today
    @today ||= Time.zone.now.strftime('%Y%m%d')
  end

  def log_job_metadata
    logger.with_fields = { activejob_id: job_id, request_id: }
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
