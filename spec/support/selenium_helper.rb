require 'capybara/rspec'
require 'selenium-webdriver'
require 'docker'

module UCBLIT
  module SeleniumHelper
    class << self
      def configure!
        configurator = Docker.running_in_container? ? GridConfigurator.new : LocalConfigurator.new
        configurator.configure!
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
        Capybara.register_driver(driver_name) { |app| new_driver(app, chrome_args) }
        Capybara.javascript_driver = driver_name

        # these accessors won't be in scope when the config block is executed,
        # so we capture them as local variables
        driver_name = self.driver_name
        webmock_options = self.webmock_options

        RSpec.configure do |config|
          config.before(:each, type: :system) do
            driven_by(driver_name)
            WebMock.disable_net_connect!(**webmock_options)
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
        '--disable-dev-shm-usage',
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
            chromeOptions: { args: chrome_args }
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
          options: ::Selenium::WebDriver::Chrome::Options.new(args: chrome_args)
        )
      end
    end
  end
end
