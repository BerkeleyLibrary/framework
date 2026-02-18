require 'rails_helper'
require 'alma_helper'

module CalnetHelper
  # Lisa Weber's UID, hard-coded in FrameworkUsers
  STACK_REQUEST_ADMIN_UID = '7165'.freeze

  # Mocks a calnet login as the specified patron, and stubs the corresponding
  # Millennium patron dump file. Suitable for calling from a before() block.
  # Should be paired with {CalnetHelper#logout!}
  #
  # NOTE: because this relies on an RSpec partial double, it can't be called
  #       from an around:each hook or a before:suite hook, only from a before:each
  #       hook or inside an individual test case.
  #
  # @return [User] the User object created by the SessionsController.
  def login_as_patron(patron_id)
    stub_patron_dump(patron_id)
    mock_login(patron_id)
  end

  # Wraps the provided block in login_as() / logout!() calls. Useful when it's
  # not possible to know the patron ID in a before() block.
  #
  # NOTE: because this relies on an RSpec partial double, it can't be called
  #       from an around:each hook or a before:suite hook, only from a
  #       before:each hook or inside an individual test case.
  #
  # @@yield [User] the User object created by the SessionsController.
  def with_patron_login(patron_id)
    user = login_as_patron(patron_id)
    yield user
  rescue StandardError => e
    puts "#{e}\n\t#{e.backtrace.join("\n\t")}" # rubocop:disable Rails/Output
    raise
  ensure
    logout!
  end

  # Mocks a calnet login as the specified patron, returning the user object
  # created by the SessionsController.
  #
  # NOTE: because this relies on an RSpec partial double, it can't be called
  #       from an around:each hook or a before:suite hook, only from a before:each
  #       hook or inside an individual test case.
  #
  # @return [User] the User object created by the SessionsController.
  def mock_login(uid)
    auth_hash = auth_hash_for(uid)
    mock_omniauth_login(auth_hash)
  end

  def auth_hash_for(uid)
    calnet_yml_file = "spec/data/calnet/#{uid}.yml"
    raise IOError, "No such file: #{calnet_yml_file}" unless File.file?(calnet_yml_file)

    auth_hash = YAML.load_file(calnet_yml_file)
    
    # Merge in default extra fields from application config
    if Rails.application.config.respond_to?(:calnet_test_defaults)
      defaults = Rails.application.config.calnet_test_defaults.stringify_keys
      auth_hash['extra'] = defaults.merge(auth_hash['extra'] || {})
    end
    
    auth_hash
  end

  # Logs out. Suitable for calling in an after() block.
  def logout!
    unless respond_to?(:page)
      # Selenium doesn't know anything about webmock and will just hit the real logout path
      stub_request(:get, 'https://auth-test.berkeley.edu/cas/logout').to_return(status: 200)
      without_redirects { do_get logout_path }
    end

    # ActionDispatch::TestProcess#session delegates to request.session,
    # but doesn't check whether it's actually present
    request.reset_session if request

    OmniAuth.config.mock_auth[:calnet] = nil
    CapybaraHelper.delete_all_cookies if defined?(CapybaraHelper)
  end

  # Mocks an OmniAuth login with the specified hash, returning the user object
  # created by the SessionsController.
  #
  # NOTE: because this relies on an RSpec partial double, it can't be called
  #       from an around:each hook or a before:suite hook, only from a before:each
  #       hook or inside an individual test case.
  #
  # @return [User] the User object created by the SessionsController.
  def mock_omniauth_login(auth_hash)
    last_signed_in_user = nil

    # We want the actual user object from the session, but system specs don't provide
    # access to it, so we intercept it at sign-in
    allow_any_instance_of(SessionsController).to receive(:sign_in).and_wrap_original do |m, *args|
      last_signed_in_user = args[0]
      m.call(*args)
    end
    log_in_with_omniauth(auth_hash)

    last_signed_in_user
  end

  # Gets the specified URL, either via the driven browser (in a system spec)
  # or directly (in a request spec)
  def do_get(path)
    return visit(path) if respond_to?(:visit)

    get(path)
  end

  # Capybara Rack::Test mock browser is notoriously stupid about external redirects
  # https://github.com/teamcapybara/capybara/issues/1388
  def without_redirects
    return yield unless can_disable_redirects?

    page.driver.follow_redirects?.tap do |was_enabled|
      page.driver.options[:follow_redirects] = false
      yield
    ensure
      page.driver.options[:follow_redirects] = was_enabled
    end
  end

  private

  def log_in_with_omniauth(auth_hash)
    OmniAuth.config.mock_auth[:calnet] = auth_hash
    do_get login_path

    Rails.application.env_config['omniauth.auth'] = auth_hash
    do_get omniauth_callback_path(:calnet)
  end

  def can_disable_redirects?
    respond_to?(:page) && page.driver.respond_to?(:follow_redirects?)
  end
end

RSpec.configure do |config|
  config.include(CalnetHelper)
end
