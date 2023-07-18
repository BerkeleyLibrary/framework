Rails.application.configure do
  config.good_job = {
    # AP-151 : Moving GJ to a separate container so async in test, external in production and development
    execution_mode: (Rails.env.test? ? :async : :external),
    on_thread_error: ->(exception) { Rails.logger.error(exception) }, # default
    max_threads: ENV.fetch('GOOD_JOB_MAX_THREADS', 5),
    poll_interval: 30,
    shutdown_timeout: 25
  }
end
