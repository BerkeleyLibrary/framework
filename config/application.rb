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

    config.altmedia = config_for(:altmedia)
    config.altmedia['expect_url'] = URI.parse(config.altmedia['expect_url'])
    config.altmedia['patron_url'] = URI.parse(config.altmedia['patron_url'])

    config.active_job.queue_adapter = :async

    config.action_mailer.delivery_method = :smtp
    config.action_mailer.smtp_settings = {
      address: 'smtp.gmail.com',
      port: '587',
      domain: 'lib.berkeley.edu',
      user_name: config.altmedia['mail_smtp_username'],
      password: config.altmedia['mail_smtp_password'],
      authentication: 'plain',
      enable_starttls_auto: true,
    }

    # Sets defaults for the mail() method (:from, :reply_to, ...)
    config.action_mailer.default_options = {
      to: config.altmedia['mail_confirm_email'],
      cc: config.altmedia['mail_admin_email'],
    }
  end
end
