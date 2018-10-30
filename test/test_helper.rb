ENV['RAILS_ENV'] ||= 'test'

require_relative '../config/environment'
require 'rails/test_help'
require 'minitest/autorun'
require 'vcr'

VCR.configure do |config|
  config.cassette_library_dir = "test/fixtures/cassettes"
  config.default_cassette_options = {:record => :new_episodes}
  config.hook_into :webmock
end

module ModelHelper
  # Applies a table of attribute tests to a given object. 'tests' is a hash of
  # attribute_name => [:assertion, *assert_args]. The :assertion is applied to
  # the given arguments and the value of the given attribute.
  def assert_attrs(obj, tests)
    tests.each do |key, cmp|
      func, *args = cmp
      args << obj.send(key)
      send(func, *args)
    end
  end

  def assert_email(email, cc: nil, bcc: nil, to: nil, subject: nil)
    assert_nil email.subject if subject.nil?
    assert_equal subject, email.subject unless subject.nil?

    assert_nil email.to if to.nil?
    assert_equal to, email.to unless to.nil?

    assert_nil email.cc if cc.nil?
    assert_equal cc, email.cc unless cc.nil?

    assert_nil email.bcc if bcc.nil?
    assert_equal bcc, email.bcc unless bcc.nil?
  end
end

module OmniAuthHelper
  def logout
    get '/logout'
    OmniAuth.config.mock_auth[:calnet] = nil

    follow_redirect!
  end

  def with_login(id)
    mocks = YAML.load_file(file_fixture('omniauth.yml'))
    mock_hash = OmniAuth::AuthHash.new(mocks.fetch(id.to_s))

    OmniAuth.config.mock_auth[:calnet] = mock_hash
    mocked_calnet = OmniAuth.config.mock_auth[:calnet]

    get login_path
    assert_response :redirect

    Rails.application.env_config["omniauth.auth"] = mocked_calnet
    get omniauth_callback_path(:calnet)
    assert_redirected_to home_path

    begin
      yield
    ensure
      logout
    end
  end
end

module SshHelper
  # Executes the block in a context in which Net::SSH.start() is stubbed out
  # to return a defined "result" and assert that we've passed the right args.
  def with_stubbed_ssh(result, &block)
    stubbed_connection = lambda do |host, user, opts|
      assert_equal 'vm161.lib.berkeley.edu', host
      assert_equal 'altmedia', user
      assert_equal ({ non_interactive: true }), opts

      case result
      when :raised then raise StandardError, "SSH connection failed"
      when :failed then 'Failed'
                   else 'Finished Successfully'
      end
    end

    travel_to Date.new(2018, 1, 1) do
      Net::SSH.stub :start, stubbed_connection, &block
    end
  end
end

class ActionDispatch::IntegrationTest
  include OmniAuthHelper
end

class ActiveSupport::TestCase
  include ModelHelper
  include SshHelper
end
