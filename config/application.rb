require_relative 'boot'
require 'rails/all'
Bundler.require(*Rails.groups)

module Framework
  class Application < Rails::Application
    class << self

      GJ_CONFIG_ATTRS = %i[
        execution_mode
        queue_string
        max_threads
        poll_interval
        max_cache
        shutdown_timeout
        enable_cron?
        cron
        cleanup_discarded_jobs?
        cleanup_preserved_jobs_before_seconds_ago
        cleanup_interval_jobs
        cleanup_interval_seconds
        inline_execution_respects_schedule?
      ].freeze

      def log_good_job_config!
        gj_config = GJ_CONFIG_ATTRS.to_h do |attr|
          [attr, GoodJob.configuration.send(attr)]
        end

        Rails.logger.info('GoodJob configured', { config: gj_config })
      end

      def log_active_storage_config!
        active_storage_service = ActiveStorage::Blob.service
        return Rails.logger.info("ActiveStorage service: #{active_storage_service}") unless active_storage_service.respond_to?(:root)
        return Rails.logger.warn('ActiveStorage root not set') unless (active_storage_root = active_storage_service.root)

        log_active_storage_root!(active_storage_root)
      end

      private

      def log_active_storage_root!(active_storage_root)
        stat = File.stat(active_storage_root)
        mode_str = format('%o', stat.mode)
        details = { path: active_storage_root, type: stat.ftype, mode: mode_str, uid: stat.uid, gid: stat.gid }
        Rails.logger.info('ActiveStorage root set', details:)
      rescue Errno::ENOENT
        Rails.logger.warn("ActiveStorage root #{active_storage_root} does not exist")
      end

    end

    config.load_defaults 7.1

    # Load our custom config. This is implicitly consumed in a few remaining
    # places (e.g. RequestMailer). A good development improvement would be to
    # inject those configs like we do with the Patron class.
    config.altmedia = config_for(:altmedia)

    # configs for libproxy validations
    config.libproxy = config_for(:libproxy)

    config.tind_marc = config_for(:tind_marc)

    config.doemoff_patron_email = config_for(:doemoff_patron_email)

    config.active_job.queue_adapter = :good_job

    # @note By default, Rails wraps fields that contain a validation error with
    #   a div classed "field_with_errors". This messes up Bootstrap's styling
    #   for feedback messages, so I've disabled the Rails' default.
    config.action_view.field_error_proc = proc { |tag, _instance| tag }

    # Alma API for handling Fees:
    config.alma_api_url = config.altmedia['alma_api_url']
    config.alma_api_key = config.altmedia['alma_api_key']
    config.alma_sandbox_key = config.altmedia['alma_sandbox_key']

    # Valid groups for libproxy access based on Alma groups
    config.libproxy_groups = config.libproxy['valid_groups']

    # Tind set values for marc inserts
    config.tind_resource_types = config.tind_marc['resource_types']
    config.tind_restrictions = config.tind_marc['restrictions']
    config.tind_locations = config.tind_marc['locations']
    config.tind_data_root_dir = config.tind_marc['data_root_dir']

    # Set values for Doe/Moffitt patron email sender
    config.patron_sender = config.doemoff_patron_email['sender']

    # Setup for Alma Marc Record
    # Alma SRU hostname
    config.alma_sru_host = ENV.fetch('LIT_ALMA_SRU_HOST', 'berkeley.alma.exlibrisgroup.com')
    # Alma institution code
    config.alma_institution_code = ENV.fetch('LIT_ALMA_INSTITUTION_CODE', '01UCS_BER')
    # Alma Primo host
    config.alma_primo_host = ENV.fetch('LIT_ALMA_PRIMO_HOST', 'search.library.berkeley.edu')
    # Alma view state key to use when generating Alma permalinks
    config.alma_permalink_key = ENV.fetch('LIT_ALMA_PERMALINK_KEY', 'iqob43')

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

    config.after_initialize do
      BuildInfo.log!
      log_active_storage_config!
      log_good_job_config!
    end
  end
end
