require 'rails_helper'
require 'patron_helper'

# Mocks a calnet login as the specified patron, and stubs the corresponding
# Millennium patron dump file. Suitable for calling from a before() block.
#
# @return [User] A user object created from the specified mock data (not the
#                actual object from the session)
def login_as(patron_id)
  stub_patron_dump(patron_id)
  mock_calnet_login(patron_id)
end

# Logs out. Suitable for calling in an after() block.
def logout!
  OmniAuth.config.mock_auth[:calnet] = nil
  stub_request(:get, 'https://auth-test.berkeley.edu/cas/logout').to_return(status: 200)
  without_redirects { do_get logout_path }
end

# Wraps the provided block in login_as() / logout!() calls. Useful when it's
# not possible to know the patron ID in a before() block.
# @@yield [User] A user object created from the specified mock data
def with_login(patron_id)
  user = login_as(patron_id)
  yield user
rescue StandardError => e
  puts "#{e}\n\t#{e.backtrace.join("\n\t")}"
  raise
ensure
  logout!
end

# Mocks a calnet login as the specified patron
def mock_calnet_login(patron_id)
  calnet_yml_file = "spec/data/calnet/#{Patron::Dump.escape_patron_id(patron_id)}.yml"
  raise IOError, "No such file: #{calnet_yml_file}" unless File.file?(calnet_yml_file)

  auth_hash = YAML.load_file(calnet_yml_file)
  OmniAuth.config.mock_auth[:calnet] = auth_hash
  do_get login_path

  Rails.application.env_config['omniauth.auth'] = auth_hash
  do_get omniauth_callback_path(:calnet)

  User.from_omniauth(auth_hash)
end

# Gets the specified URL, either via the driven browser (in a system spec)
# or directly (in a request spec)
def do_get(path)
  return visit(path) if respond_to?(:visit)

  get(path)
end

# Capybara RackTest mock browser is notoriously stupid about external redirects
# https://github.com/teamcapybara/capybara/issues/1388
def without_redirects
  if respond_to?(:page)
    was_enabled = page.driver.follow_redirects?
    begin
      page.driver.options[:follow_redirects] = false
      yield
    ensure
      page.driver.options[:follow_redirects] = was_enabled
    end
  else
    yield
  end
end
