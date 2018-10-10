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
  end
end
