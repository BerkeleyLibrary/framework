# frozen_string_literal: true

# Health check configuration
require 'berkeley_library/util/uris/head_check'

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

# Ensure TIND API is working.
tind_health_check_url = "#{Rails.application.config.tind_base_uri}api/v1/search?In=en"
OkComputer::Registry.register 'thind-api', BerkeleyLibrary::Util::HeadCheck.new(tind_health_check_url)

# Ensure HathiTrust API is working.
OkComputer::Registry.register 'hathitrust-api', BerkeleyLibrary::Util::HeadCheck.new(Rails.application.config.hathiTrust_health_check_url)

# Ensure ARIN Whois API is working.
OkComputer::Registry.register 'whois-arin-api', BerkeleyLibrary::Util::HeadCheck.new(Rails.application.config.whois_health_check_url)

# Ensure Berkeley ServiceNow is accessible.
OkComputer::Registry.register 'berkeley-service-now', BerkeleyLibrary::Util::HeadCheck.new(Rails.application.config.berkeley_service_now_health_check_url)

# Ensure PayPal Payflow is accessible.
OkComputer::Registry.register 'paypal-payflow', OkComputer::HttpCheck.new(Rails.application.config.paypal_payflow_url)

# Since the WorldCat API service requests dynamically generated OCLC tokens, we are not doing a health check for it.
