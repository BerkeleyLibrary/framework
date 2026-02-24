require Rails.root.join('app/mailers/interceptor/mailing_list_interceptor')
require 'active_support/core_ext/integer/time'

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # Code is not reloaded between requests.
  config.enable_reloading = false

  # Eager load code on boot for better performance and memory savings (ignored by Rake tasks).
  config.eager_load = true

  # Full error reports are disabled.
  config.consider_all_requests_local = false

  # Turn on fragment caching in view templates.
  config.action_controller.perform_caching = true

  # Cache assets for far-future expiry since they are all digest stamped.
  config.public_file_server.headers = { 'Cache-Control' => "public, max-age=#{1.year.to_i}" }

  # Enable serving of images, stylesheets, and JavaScripts from an asset server.
  # config.asset_host = 'http://assets.example.com'

  # Store uploaded files on the local file system (see config/storage.yml for options).
  config.active_storage.service = :local

  # Assume all access to the app is happening through a SSL-terminating reverse proxy.
  # config.assume_ssl = true

  # Force all access to the app over SSL, use Strict-Transport-Security, and use secure cookies.
  config.force_ssl = true

  # Prepend all log lines with the following tags.
  config.log_tags = [:request_id]

  # Change to "debug" to log everything (including potentially personally-identifiable information!)
  config.log_level = ENV.fetch('RAILS_LOG_LEVEL', 'info')

  # Replace the default in-process memory cache store with a durable alternative.
  # config.cache_store = :mem_cache_store

  # Replace the default in-process and non-durable queuing backend for Active Job.
  # config.active_job.queue_adapter = :resque

  # Ignore bad email addresses and do not raise email delivery errors.
  # Set this to true and configure the email server for immediate delivery to raise delivery errors.
  # config.action_mailer.raise_delivery_errors = false

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation cannot be found).
  config.i18n.fallbacks = true

  # Send deprecation notices to registered listeners.
  config.active_support.deprecation = :notify

  # Do not dump schema after migrations.
  config.active_record.dump_schema_after_migration = false

  # Only use :id for inspections in production.
  config.active_record.attributes_for_inspect = [:id]

  # Enable DNS rebinding protection and other `Host` header attacks.
  # config.hosts = [
  #   "example.com",     # Allow requests from example.com
  #   /.*\.example\.com/ # Allow requests from subdomains like `www.example.com`
  # ]
  # Skip DNS rebinding protection for the default health check endpoint.
  # config.host_authorization = { exclude: ->(request) { request.path == "/up" } }

  # Use GMail in production
  config.action_mailer.delivery_method = :smtp
  config.action_mailer.smtp_settings = {
    address: 'smtp.gmail.com',
    port: 465,
    domain: config.altmedia['mail_smtp_domain'],
    user_name: config.altmedia['mail_smtp_username'],
    password: config.altmedia['mail_smtp_password'],
    authentication: 'plain',
    tls: true,
    open_timeout: ENV.fetch('MAIL_OPEN_TIMEOUT', 5).to_i,
    read_timeout: ENV.fetch('MAIL_READ_TIMEOUT', 5).to_i
  }

  if ENV['INTERCEPT_EMAILS'].present?
    # Route emails to a mailing list in staging
    interceptor = Interceptor::MailingListInterceptor.new
    ActionMailer::Base.register_interceptor(interceptor)
  end

  # Configure the default host - this is used by Stack Pass's mailer, to create a link
  # back to the application (directly to the approval form for an pass request):
  # For master staging area use:
  # config.action_mailer.default_url_options = { host: 'framework.ucblib.org' }

  # For production make use:
  config.action_mailer.default_url_options = { host: 'framework.lib.berkeley.edu' }
end
