require 'spec_helper'

require File.expand_path('../config/environment', __dir__)
require 'rspec/rails'

require 'ssh_helper'
require 'alma_helper'

RSpec.configure do |config|
  config.include ActiveSupport::Testing::TimeHelpers

  config.use_transactional_fixtures = false

  config.before(:suite) do
    DatabaseCleaner.clean_with(:truncation)
  end

  # Workaround for https://github.com/DatabaseCleaner/database_cleaner-active_record/issues/86
  config.after do
    DatabaseCleaner.clean_with(:truncation)
  end

  config.around(:each, type: :request) do |example|
    handler = ApplicationController.remove_rescue_handler_for(StandardError)
    begin
      example.run
    ensure
      ApplicationController.restore_rescue_handler(handler) if handler
    end
  end
end
