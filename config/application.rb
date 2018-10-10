# Read Docker secrets into the environment
Dir['/run/secrets/*'].each do |filepath|
  secret = File.read(filepath)
  secret_name = File.basename(filepath)
  ENV[secret_name] = secret unless secret.empty?
end

require_relative 'boot'
require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Altscan
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 5.2

    # Load our custom altmedia config file
    config.altmedia = config_for(:altmedia)
    config.altmedia['expect_url'] = URI.parse(config.altmedia['expect_url'])
    config.altmedia['patron_url'] = URI.parse(config.altmedia['patron_url'])

    config.active_job.queue_adapter = :async

    # NOTE(dcschmidt): By default, Rails wraps fields that contain a validation
    # error with a div classed "field_with_errors". This messes up Bootstrap's
    # styling for feedback messages, so I've disabled the Rails' default.
    config.action_view.field_error_proc = Proc.new { |tag, instance| tag }
  end
end
