class ApplicationJob < ActiveJob::Base
  attr_accessor :request_id

  before_enqueue do |job|
    job.request_id = Current.request_id
  end

  before_perform :restore_request_id, :log_job_metadata

  def serialize
    super.merge('request_id' => request_id)
  end

  def deserialize(job_data)
    super
    self.request_id = job_data['request_id']
  end

  def today
    @today ||= Time.zone.now.strftime('%Y%m%d')
  end

  private

  def restore_request_id
    self.request_id ||= Current.request_id
  end

  def log_job_metadata
    logger.with_fields = { activejob_id: job_id, request_id: request_id }
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
