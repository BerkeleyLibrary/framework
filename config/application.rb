# Read Docker secrets into the environment. Must be before 'rails/all'.
require_relative '../lib/docker'
Docker::Secret.setup_environment!

require_relative 'boot'
require 'rails/all'
Bundler.require(*Rails.groups)
require_relative '../app/loggers/altmedia_logger'

module Framework
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 5.2

    # Load our custom config. This is implicitly consumed in a few remaining
    # places (e.g. RequestMailer). A good development improvement would be to
    # inject those configs like we do with the Patron class.
    config.altmedia = config_for(:altmedia)

    # @todo Switch to a persistent backend store like delayed_job
    config.active_job.queue_adapter = :async

    # @note By default, Rails wraps fields that contain a validation error with
    #   a div classed "field_with_errors". This messes up Bootstrap's styling
    #   for feedback messages, so I've disabled the Rails' default.
    config.action_view.field_error_proc = proc { |tag, _instance| tag }
    config.lograge.enabled = true
    config.logger = AltmediaLogger::Logger.new($stdout)
    config.lograge.custom_options = ->(event) do
      {
        time: Time.now,
        request_id: event.payload[:headers].env['action_dispatch.request_id'],
        remote_ip: event.payload[:headers][:REMOTE_ADDR]
      }
    end
    config.lograge.formatter = Class.new do |fmt|
      def fmt.call(data)
        { msg: 'Request', request: data }
      end
    end
    # Configure Patron API lookups. Uses before_initialize hook so that
    # autoloading finds the Patron::Record class.
    config.before_initialize do
      Patron::Record.api_base_url = URI.parse(config.altmedia['patron_url'])
      Patron::Record.expect_url = URI.parse(config.altmedia['expect_url'])
    end
  end
end
