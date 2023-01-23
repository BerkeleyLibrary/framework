Rails.application.configure do
  config.good_job = {
    # TODO: use :async in test, :external in production
    execution_mode: :async,
    on_thread_error: ->(exception) { Rails.logger.error(exception) }, # default
    max_threads: ENV.fetch('GOOD_JOB_MAX_THREADS', 5),
    poll_interval: 30,
    shutdown_timeout: 25
  }
end
