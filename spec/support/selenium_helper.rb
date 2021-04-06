require 'capybara'

module UCBLIT
  module SeleniumHelper
    class Configurator
      def configure!
        register_driver!
        configure_rspec!
      end
    end

    class GridConfigurator < Configurator
      def register_driver!
        Capybara.register_driver :jenkins_selenium_grid do |app|
          Capybara::Selenium::Driver.new(
            app,
            browser: :remote,
            url: 'http://selenium:4444/wd/hub',
            desired_capabilities: :chrome
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
      def register_driver!
        require 'selenium-webdriver'

        Capybara.register_driver :selenium_chrome_headless do |app|
          options = ::Selenium::WebDriver::Chrome::Options.new

          options.add_argument('--headless')
          options.add_argument('--no-sandbox')
          options.add_argument('--disable-dev-shm-usage')
          options.add_argument('--window-size=1400,1400')

          Capybara::Selenium::Driver.new(app, browser: :chrome, options: options)
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
