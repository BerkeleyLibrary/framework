require 'spec_helper'

require File.expand_path('../config/environment', __dir__)
require 'rspec/rails'

require 'ssh_helper'
require 'patron_helper'

RSpec.configure do |config|
  config.around(:each, type: :request) do |example|
    handler = ApplicationController.remove_rescue_handler_for(StandardError)
    begin
      example.run
    ensure
      ApplicationController.restore_rescue_handler(handler) if handler
    end
  end
end
