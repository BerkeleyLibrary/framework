# ------------------------------------------------------------
# Rails

ENV['RAILS_ENV'] = 'test'

# ------------------------------------------------------------
# Dependencies

require 'colorize'
require 'webmock/rspec'

require 'simplecov' if ENV['COVERAGE']

# ------------------------------------------------------------
# RSpec configuration

RSpec.configure do |config|
  config.color = true
  config.tty = true
  config.formatter = :documentation

  config.around(:each) do |example|
    WebMock.disable_net_connect!(
      allow_localhost: true,
      # prevent running out of file handles -- see https://github.com/teamcapybara/capybara#gotchas
      net_http_connect_on_start: true
    )
    example.run
  ensure
    WebMock.allow_net_connect!
  end

  # Required for shared contexts (e.g. in ssh_helper.rb); see
  # https://relishapp.com/rspec/rspec-core/docs/example-groups/shared-context#background
  config.shared_context_metadata_behavior = :apply_to_host_groups
end

# Temporarily redirects log output to a StringIO object, runs
# the specified block, and returns the captured log output.
#
# @param &block The block to run
# @return [String] The log output
def capturing_log(&block)
  logdev = Rails.logger.instance_variable_get(:@logdev)
  dev_actual = logdev.instance_variable_get(:@dev)
  dev_tmp = StringIO.new
  begin
    logdev.instance_variable_set(:@dev, dev_tmp)
    block.call
  ensure
    logdev.instance_variable_set(:@dev, dev_actual)
  end
  dev_tmp.string
end
