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

    config.active_job.queue_adapter = :async

    config.action_mailer.delivery_method = :smtp
    config.action_mailer.smtp_settings = {
      address:              'smtp.gmail.com',
      port:                 587,
      domain:               'lib.berkeley.edu',
      user_name:            'lib-noreply@berkeley.edu',
      password:             ENV['MAIL_PASSWORD'],
      authentication:       'plain',
      enable_starttls_auto: true,
    }

    # Sets defaults for the mail() method (:from, :reply_to, ...)
    config.action_mailer.default_options = {
      # NOTE(dzuckerm): Set the email address to receive opt out requests and
      # failure notifications. Me for testing.
      to: ENV['ADMIN_EMAIL'] || 'dzuckerm@library.berkeley.edu',
    }

    # Provides the full base path to the patron API.
    config.patron_url = URI.parse(ENV.fetch('PATRON_URL') {
      'https://dev-oskicatp.berkeley.edu:54620/PATRONAPI/'
    })

    # Provide the path to the expect script as an SSH URI.
    config.expect_url = URI.parse(ENV.fetch('EXPECT_URL') {
      'ssh://altmedia@vm161.lib.berkeley.edu/home/altmedia/bin/mkcallnote'
    })
  end
end
