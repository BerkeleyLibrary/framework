module ExceptionHandling
  extend ActiveSupport::Concern

  # rubocop:disable Metrics/BlockLength
  included do
    # Order exceptions from most generic to most specific.

    rescue_from StandardError do |error|
      log_error(error)
      render :standard_error, status: :internal_server_error
    end

    rescue_from Error::UnauthorizedError do |error|
      log_error(error)
      redirect_to login_path(url: request.fullpath)
    end

    rescue_from Error::PatronApiError do |error|
      log_error(error)
      render :patron_api_error, status: :service_unavailable
    end

    rescue_from Error::PatronNotFoundError do |error|
      log_error(error)
      render :patron_not_found_error, status: :forbidden
    end

    rescue_from Error::ForbiddenError do |error|
      log_error(error)
      render :forbidden, status: :forbidden
    end

    rescue_from Error::PatronNotEligibleError do |error|
      log_error(error)
      @error = error # so view has access
      render :patron_not_eligible_error, status: :forbidden
    end

    rescue_from Error::PatronBlockedError do |error|
      log_error(error)
      render :blocked, status: :forbidden
    end
  end
  # rubocop:enable Metrics/BlockLength
end
