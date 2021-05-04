require 'active_support/inflector'
require 'capybara/rspec'
require 'rails_helper'
require 'selenium-webdriver'

require 'docker'

module CapybaraHelper
  # Capybara artifact path
  # (see https://www.rubydoc.info/github/jnicklas/capybara/Capybara.configure)
  #
  # NOTE: Rails' system test helpers insist on writing screenshots to
  #       `tmp/screenshots` regardless of Capybara configuration:
  #       see https://github.com/rails/rails/issues/41828.
  #
  #       In the Docker image we symlink that to `artifacts/screenshots`.
  SAVE_PATH = 'artifacts/capybara'.freeze

  class << self
    def configure!
      configurator = Docker.running_in_container? ? GridConfigurator.new : LocalConfigurator.new
      configurator.configure!
    end

    def print_javascript_log(msg = nil, out = $stderr)
      out.write("#{msg}: #{formatted_javascript_log}\n")
    end

    def local_project_root
      File.expand_path('..', __dir__)
    end

    def browser_project_root
      Docker.running_in_container? ? '/build' : local_project_root
    end

    private

    def browser
      Capybara.current_session.driver.browser
    end

    def formatted_javascript_log(indent = '  ')
      logs = browser.manage.logs.get(:browser)
      return 'No entries logged to JavaScript console' if logs.nil? || logs.empty?

      StringIO.new.tap do |out|
        out.write("#{logs.size} entries logged to JavaScript console:\n")
        logs.each_with_index { |entry, i| out.write("#{indent}#{i}\t#{entry}\n") }
      end.string
    end

    def remove_if_empty(path)
      return unless File.directory?(path)
      return unless Dir.entries(path).empty?

      FileUtils.rm_rf(path)
    end

    def ensure_directory(path)
      path.tap do |p|
        FileUtils.rm_rf(p)
        FileUtils.mkdir_p(p)
      end
    end
  end

  class Configurator
    DEFAULT_CHROME_ARGS = ['--window-size=2560,1344'].freeze

    DEFAULT_WEBMOCK_OPTIONS = {
      allow_localhost: true,
      # prevent running out of file handles -- see https://github.com/teamcapybara/capybara#gotchas
      net_http_connect_on_start: true
    }.freeze

    attr_reader :driver_name
    attr_reader :chrome_args
    attr_reader :webmock_options

    def initialize(driver_name, chrome_args: [], webmock_options: {})
      @driver_name = driver_name
      @chrome_args = DEFAULT_CHROME_ARGS + chrome_args
      @webmock_options = DEFAULT_WEBMOCK_OPTIONS.merge(webmock_options)
    end

    def configure!
      configure_capybara!
      configure_rspec!
    end

    private

    def configure_capybara!
      Capybara.save_path = CapybaraHelper::SAVE_PATH
      Capybara.register_driver(driver_name) do |app|
        new_driver(app, chrome_args)
      end
      Capybara.javascript_driver = driver_name
    end

    def configure_rspec!
      # these accessors won't be in scope when the config block is executed,
      # so we capture them as local variables
      driver_name = self.driver_name
      webmock_options = self.webmock_options

      RSpec.configure do |config|
        config.around(:each, type: :system) do |example|
          driven_by(driver_name)
          WebMock.disable_net_connect!(**webmock_options)

          example.run
        ensure
          if example.exception
            test_name = example.metadata[:full_description]
            test_source_location = example.metadata[:location]
            CapybaraHelper.print_javascript_log("#{test_name} (#{test_source_location}) failed")
          end
        end
      end
    end
  end

  class GridConfigurator < Configurator
    CAPYBARA_APP_HOSTNAME = 'app.test'.freeze
    SELENIUM_HOSTNAME = 'selenium.test'.freeze

    # noinspection RubyLiteralArrayInspection
    GRID_CHROME_ARGS = [
      # Docker containers default to a /dev/shm too small for Chrome's cache
      '--disable-dev-shm-usage', # TODO: do we still need this?
      '--disable-gpu'
    ].freeze

    def initialize
      super(:selenium_grid, webmock_options: { allow: [SELENIUM_HOSTNAME] }, chrome_args: GRID_CHROME_ARGS)
    end

    def new_driver(app, chrome_args)
      Capybara::Selenium::Driver.new(
        app,
        browser: :remote,
        url: "http://#{SELENIUM_HOSTNAME}:4444/wd/hub",
        desired_capabilities: ::Selenium::WebDriver::Remote::Capabilities.chrome(
          chromeOptions: { args: chrome_args },
          'goog:loggingPrefs' => {
            browser: 'ALL', client: 'ALL', driver: 'ALL', server: 'ALL'
          }
        )
      )
    end

    def configure!
      super

      RSpec.configure do |config|
        config.before(:each, type: :system) do
          Capybara.server_port = ENV['CAPYBARA_SERVER_PORT'] if ENV['CAPYBARA_SERVER_PORT']
          Capybara.app_host = "http://#{CAPYBARA_APP_HOSTNAME}"
          Capybara.server_host = '0.0.0.0'
          Capybara.always_include_port = true
        end
      end
    end
  end

  class LocalConfigurator < Configurator
    def initialize
      super(:selenium_headless, chrome_args: ['--headless'])
    end

    def new_driver(app, chrome_args)
      Capybara::Selenium::Driver.new(
        app,
        browser: :chrome,
        options: ::Selenium::WebDriver::Chrome::Options.new(args: chrome_args),
        desired_capabilities: {
          'goog:loggingPrefs' => {
            browser: 'ALL', client: 'ALL', driver: 'ALL', server: 'ALL'
          }
        }
      )
    end
  end
end

CapybaraHelper.configure!
