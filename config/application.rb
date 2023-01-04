require_relative 'boot'
require 'rails/all'
Bundler.require(*Rails.groups)

module Framework
  class Application < Rails::Application
    config.load_defaults 7.0

    # Load our custom config. This is implicitly consumed in a few remaining
    # places (e.g. RequestMailer). A good development improvement would be to
    # inject those configs like we do with the Patron class.
    config.altmedia = config_for(:altmedia)

    # configs for libproxy validations
    config.libproxy = config_for(:libproxy)

    # TODO: Switch to a persistent backend store like delayed_job
    #       (but make sure to update async logging tests in jobs_helper.rb)
    config.active_job.queue_adapter = :good_job

    # @note By default, Rails wraps fields that contain a validation error with
    #   a div classed "field_with_errors". This messes up Bootstrap's styling
    #   for feedback messages, so I've disabled the Rails' default.
    config.action_view.field_error_proc = proc { |tag, _instance| tag }

    # Alma API for handling Fees/Fines:
    config.alma_api_url = config.altmedia['alma_api_url']
    config.alma_api_key = config.altmedia['alma_api_key']

    # Valid groups for libproxy access based on Alma groups
    config.libproxy_groups = config.libproxy['valid_groups']

    # Setup paypal payflow link:
    config.paypal_payflow_url = config.altmedia['paypal_payflow_url']
    config.paypal_payflow_login = config.altmedia['paypal_payflow_login']

    # Setup berkeley_library-tind for TIND Downloader:
    config.tind_base_uri = config.altmedia['tind_base_uri']
    config.tind_api_key = config.altmedia['tind_api_key']

    config.to_prepare do
      GoodJob::JobsController.class_eval do
        include AuthSupport
        include ExceptionHandling
        before_action :require_framework_admin!
      end
    end

  end
end
