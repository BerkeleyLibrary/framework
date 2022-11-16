class ApplicationJob < ActiveJob::Base
  def today
    @today ||= Time.zone.now.strftime('%Y%m%d')
  end

  # Log an exception
  def log_error(error)
    # TODO: share code w/ApplicationController
    msg = {
      msg: error.message,
      error: error.inspect.to_s,
      cause: error.cause.inspect.to_s
    }
    msg[:backtrace] = error.backtrace if Rails.logger.level < Logger::INFO
    logger.error(msg)
  end
end
