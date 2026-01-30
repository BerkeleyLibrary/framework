# frozen_string_literal: true

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
class CustomMailerCheck < OkComputer::Check
  require 'net/smtp'
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
      mark_message "Authentication error: #{e.message}"
    rescue Net::SMTPServerBusy, Net::SMTPSyntaxError, Net::SMTPFatalError, Net::SMTPUnknownError => e
      mark_failure
      mark_message "SMTP error: #{e.message}"
    rescue IOError, Net::ReadTimeout => e
      mark_failure
      mark_message "Connection error: #{e.message}"
    rescue StandardError => e
      # Catch any other unexpected errors
      mark_failure
      mark_message "An unexpected error occurred: #{e.message}"
    end
  end
end
# rubocop:enable Metrics/MethodLength, Metrics/AbcSize

# Ensure Alma API is working.
OkComputer::Registry.register 'alma-patron-lookup', AlmaPatronCheck.new

# Ensure database migrations have been run.
OkComputer::Registry.register 'database-migrations', OkComputer::ActiveRecordMigrationsCheck.new

# Ensure connectivity to the mail system.
OkComputer::Registry.register 'custom-mailer', CustomMailerCheck.new
OkComputer::Registry.register 'action-mailer', OkComputer::ActionMailerCheck.new
