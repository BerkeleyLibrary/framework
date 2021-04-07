require 'capybara'

module UCBLIT
  module SeleniumHelper
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
            url: 'http://selenium:4444/wd/hub',
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

            Capybara.app_host = 'http://rails:3000'
            Capybara.server_host = '0.0.0.0'
            Capybara.server_port = 3000

            WebMock.disable_net_connect!(
              allow: ['selenium'],
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
        configurator = using_selenium_grid? ? GridConfigurator.new : LocalConfigurator.new
        configurator.configure!
      end

      private

      def using_selenium_grid?
        resolves_to_self?('rails') && host_exists?('selenium')
      end

      def host_exists?(hostname)
        !address_for(hostname).nil?
      end

      def address_for(hostname)
        IPSocket.getaddress(hostname)
      rescue SocketError
        nil
      end

      def resolves_to_self?(hostname)
        return false unless (host_address = address_for(hostname))

        Socket.ip_address_list.any? { |info| info.ip_address == host_address }
      end
    end
  end
end
