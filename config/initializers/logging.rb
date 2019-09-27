Rails.application.configure do

  # Log behavior set to consistently go to STDOUT and will not be output to a file
  logger = Altmedia::Logger.new(STDOUT)
  logger.formatter = config.log_formatter
  config.logger = ActiveSupport::TaggedLogging.new(logger)
  config.lograge.enabled = true

  config.lograge.custom_options = ->(event) do
    {
      time: Time.now,
      remote_ip: event.payload[:remote_ip]
    }
  end
  config.lograge.formatter = Class.new do |fmt|
    def fmt.call(data)
      { msg: 'Request', request: data }
    end
  end
end
