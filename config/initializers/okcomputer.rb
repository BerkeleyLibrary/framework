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

# Ensure Alma API is working.
OkComputer::Registry.register 'alma-patron-lookup', AlmaPatronCheck.new

# Ensure database migrations have been run.
OkComputer::Registry.register 'database-migrations', OkComputer::ActiveRecordMigrationsCheck.new

# Ensure connectivity to the mail system.
OkComputer::Registry.register 'action-mailer', OkComputer::ActionMailerCheck.new
