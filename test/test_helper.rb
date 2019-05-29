ENV['RAILS_ENV'] ||= 'test'

require 'simplecov'
require_relative '../config/environment'
require 'rails/test_help'
require 'minitest/autorun'
require 'vcr'
require 'concerns/patron_eligibility_tests'

VCR.configure do |config|
  config.cassette_library_dir = "test/fixtures/cassettes"
  config.default_cassette_options = {:record => :new_episodes}
  config.hook_into :webmock
end

class ActionDispatch::IntegrationTest
  # Execute the logout flow
  # @return [void]
  def logout
    get '/logout'
    OmniAuth.config.mock_auth[:calnet] = nil

    return_url = "https://auth#{'-test' unless Rails.env.production?}.berkeley.edu/cas/logout"
    my_domain = "auth#{'-test' unless Rails.env.production?}.berkeley.edu"
    request.headers["HTTP_HOST"] = my_domain
    assert_redirected_to return_url

    #follow_redirect!
  end

  # Return a test user with specified category of patron (blocked, library staff, etc.)
  #
  # @param [String] id a key in test/fixtures/files/omniauth.yml
  # @return [void]
  def retrieve_mock_user_hash(id)
    mocks = YAML.load_file(file_fixture('omniauth.yml'))
    mock_hash = OmniAuth::AuthHash.new(mocks.fetch(id.to_s))
  end

  # Execute the login flow with a test user
  #
  # @param [String] id a key in test/fixtures/files/omniauth.yml
  # @param [Block] block called in the context of the user being logged in
  # @return [void]
  def with_login(id, &block)
    mock_hash = retrieve_mock_user_hash(id)

    OmniAuth.config.mock_auth[:calnet] = mock_hash
    mocked_calnet = OmniAuth.config.mock_auth[:calnet]

    get login_path
    assert_response :redirect

    Rails.application.env_config["omniauth.auth"] = mocked_calnet
    get omniauth_callback_path(:calnet)
    assert_redirected_to home_path

    begin
      block.call(mocked_calnet)
    ensure
      logout
    end
  end
end

class ActiveSupport::TestCase
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
