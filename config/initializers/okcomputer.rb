# frozen_string_literal: true

require 'net/smtp'
require 'berkeley_library/util/uris/head_check'

# Health check configuration
OkComputer.logger = Rails.logger
OkComputer.check_in_parallel = true

class AlmaPatronCheck < OkComputer::Check
  TEST_PATRON_ID = '000311@lbl.gov'

  def check
    Alma::User.find(TEST_PATRON_ID)
    mark_message 'Success'
  rescue StandardError => e
    mark_failure
    Rails.logger.warn "Couldn't connect to Alma API during health check: #{e}"
    mark_message 'Failed'
  end
end

# rubocop:disable Metrics/MethodLength, Metrics/AbcSize
class MailConnectivityCheck < OkComputer::Check

  # Check that the mail password is set
  def check
    settings = ActionMailer::Base.smtp_settings
    begin
      Net::SMTP.start(
        settings[:address],
        settings[:port],
        settings[:domain],
        settings[:user_name],
        settings[:password],
        settings[:authentication],
        tls: true
      ) { mark_message 'Connection for smtp successful' }
    rescue Net::SMTPAuthenticationError => e
      mark_failure
      Rails.logger.warn "SMTP authentication error: #{e}"
      mark_message 'SMTP Error: Authentication failed. Check logs for more details'
    rescue Net::SMTPServerBusy, Net::SMTPSyntaxError, Net::SMTPFatalError, Net::SMTPUnknownError => e
      mark_failure
      Rails.logger.warn "SMTP Error: #{e}"
      mark_message 'SMTP error. Check logs for more details'
    rescue IOError, Net::ReadTimeout => e
      mark_failure
      Rails.logger.warn "SMTP Timeout: #{e}"
      mark_message 'SMTP Connection error: Timeout. Check logs for more details'
    rescue StandardError => e
      # Catch any other unexpected errors
      mark_failure
      Rails.logger.warn "SMTP standard error: #{e}"
      mark_message 'SMTP ERROR: Could not connect. Check logs for more details'
    end
  end
end
# rubocop:enable Metrics/MethodLength, Metrics/AbcSize

# Ensure SMTP can connect
OkComputer::Registry.register 'mail-connectivity', MailConnectivityCheck.new if ActionMailer::Base.delivery_method == :smtp

# Ensure Alma API is working.
OkComputer::Registry.register 'alma-patron-lookup', AlmaPatronCheck.new

# Ensure database migrations have been run.
OkComputer::Registry.register 'database-migrations', OkComputer::ActiveRecordMigrationsCheck.new

# Ensure TIND API is working.
tind_health_check_url = "#{Rails.application.config.tind_base_uri}api/v1/search?In=en"
OkComputer::Registry.register 'tind-api', BerkeleyLibrary::Util::HeadCheck.new(tind_health_check_url)

# Ensure HathiTrust API is working.
OkComputer::Registry.register 'hathitrust-api', BerkeleyLibrary::Util::HeadCheck.new(Rails.application.config.x.healthcheck_urls.hathiTrust)

# Ensure ARIN Whois API is working.
OkComputer::Registry.register 'whois-arin-api', BerkeleyLibrary::Util::HeadCheck.new(Rails.application.config.x.healthcheck_urls.whois)

# Ensure Berkeley ServiceNow is accessible.
OkComputer::Registry.register 'berkeley-service-now', BerkeleyLibrary::Util::HeadCheck.new(Rails.application.config.x.healthcheck_urls.berkeley_service_now)

# Ensure PayPal Payflow is accessible.
OkComputer::Registry.register 'paypal-payflow', OkComputer::HttpCheck.new(Rails.application.config.paypal_payflow_url)

# Since the WorldCat API service requests dynamically generated OCLC tokens, we are not doing a health check for it.
