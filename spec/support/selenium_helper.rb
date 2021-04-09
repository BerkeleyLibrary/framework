require 'capybara'

module UCBLIT
  module SeleniumHelper

    CAPYBARA_APP_HOSTNAME = 'app.test'.freeze
    SELENIUM_HOSTNAME = 'selenium.test'.freeze

    class Configurator
      DEFAULT_CHROME_ARGS = [
        '--window-size=2560,1344'
      ].freeze

      def configure!
        register_driver!
        configure_rspec!
      end

      def chrome_args
        additional_chrome_args + DEFAULT_CHROME_ARGS
      end

    end

    class GridConfigurator < Configurator

      def additional_chrome_args
        [
          # Docker containers default to a /dev/shm too small for Chrome's cache
          '--disable-dev-shm-usage',
          '--disable-gpu'
        ]
      end

      def register_driver!
        Capybara.register_driver :jenkins_selenium_grid do |app|
          Capybara::Selenium::Driver.new(
            app,
            browser: :remote,
            url: "http://#{SELENIUM_HOSTNAME}:4444/wd/hub",
            desired_capabilities: Selenium::WebDriver::Remote::Capabilities.chrome(
              chromeOptions: { args: chrome_args }
            )
          )
        end
      end

      def configure_rspec!
        RSpec.configure do |config|
          config.before(:each, type: :system) do
            driven_by(:jenkins_selenium_grid)

            Capybara.app_host = "http://#{CAPYBARA_APP_HOSTNAME}"
            Capybara.server_host = '0.0.0.0'
            Capybara.always_include_port = true

            WebMock.disable_net_connect!(
              allow: [SELENIUM_HOSTNAME],
              allow_localhost: true,
              # prevent running out of file handles -- see https://github.com/teamcapybara/capybara#gotchas
              net_http_connect_on_start: true
            )
          end
        end
      end
    end

    class LocalConfigurator < Configurator
      def additional_chrome_args
        ['--headless']
      end

      def register_driver!
        require 'selenium-webdriver'

        Capybara.register_driver :selenium_chrome_headless do |app|
          Capybara::Selenium::Driver.new(
            app,
            browser: :chrome,
            options: ::Selenium::WebDriver::Chrome::Options.new(args: chrome_args)
          )
        end

        Capybara.javascript_driver = :selenium_chrome_headless
      end

      def configure_rspec!
        RSpec.configure do |config|
          config.before(:each, type: :system) do
            driven_by(:selenium_chrome_headless)

            WebMock.disable_net_connect!(
              allow_localhost: true,
              # prevent running out of file handles -- see https://github.com/teamcapybara/capybara#gotchas
              net_http_connect_on_start: true
            )
          end
        end
      end
    end

    class << self
      def configure!
        configurator = !ENV['CI'].nil? ? GridConfigurator.new : LocalConfigurator.new
        configurator.configure!
      end
    end
  end
end
