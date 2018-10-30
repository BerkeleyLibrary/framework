# This module tells the controller what views to render and status codes to
# return when an unhandled exception bubbles up. Rails matches exceptions from
# the bottom up, so the most specific exceptions should be placed last.
#
# For a list of Rails' built-in HTTP status codes, see:
#   http://www.railsstatuscodes.com
module ErrorHandling
  extend ActiveSupport::Concern

  included do
    rescue_from StandardError do |error|
      log_error(error)
      render "errors/standard_error", status: :internal_server_error
    end

    rescue_from Framework::Errors::NotAuthenticatedError do |error|
      log_error(error)
      redirect_to login_path(url: request.fullpath)
    end

    rescue_from Framework::Errors::PatronApiError do |error|
      log_error(error)
      render "errors/patron_api_error", status: :service_unavailable
    end
  end

  def log_error(error)
    logger.error("Exception: #{error.inspect}, Cause: #{error.cause.inspect}")
  end
end
