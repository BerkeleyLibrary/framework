class ApplicationJob < ActiveJob::Base
  # This is a little unorthodox, but we want the request_id to be available as an instance variable on the job,
  # so we add it to the arguments before the job is enqueued and then pull it out in a before_perform callback.
  # Admittedly, the request_id method mutates the arguments as a side effect of pulling the request_id out.

  before_enqueue do
    arguments << { request_id: Current.request_id } if Current.request_id
  end

  before_perform :log_job_metadata

  def request_id
    r_id_hash, rest = arguments.partition { |arg| arg.is_a?(Hash) && arg.key?(:request_id) } unless defined? @request_id
    self.arguments = rest if rest.any?
    @request_id = r_id_hash.first[:request_id] if r_id_hash.any?
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
