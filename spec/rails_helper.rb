require 'spec_helper'

require File.expand_path('../config/environment', __dir__)
require 'rspec/rails'

require 'ssh_helper'
require 'patron_helper'

RSpec.configure do |config|
  config.use_transactional_fixtures = false

  config.before(:suite) do
    DatabaseCleaner.strategy = :truncation
    DatabaseCleaner.clean_with(:truncation)
  end

  config.around(:each) do |example|
    DatabaseCleaner.cleaning do
      example.run
      puts 'hello'
    end
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
