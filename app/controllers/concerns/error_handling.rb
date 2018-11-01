# This module tells the controller what views to render and status codes to
# return when an unhandled exception bubbles up. Rails matches exceptions from
# the bottom up, so the most specific exceptions should be placed last.
#
# Use `rescue_from` declarations to handle new classes of errors:
#
#   rescue_from Framework::Errors::MyNewError do |error|
#     log_error(error)
#     render "errors/my_error", status: :internal_server_error
#   end
#
# @see http://www.railsstatuscodes.com Rails HTTP status codes
# @see https://api.rubyonrails.org/v5.2.1/classes/ActiveSupport/Concern.html Docs: ActiveSupport::Concern
# @see https://api.rubyonrails.org/classes/ActiveSupport/Rescuable/ClassMethods.html#method-i-rescue_from Docs: rescue_from
module ErrorHandling
  extend ActiveSupport::Concern

  included do
    rescue_from StandardError do |error|
      log_error(error)
      render "errors/standard_error", status: :internal_server_error
    end

    rescue_from Framework::Errors::UnauthorizedError do |error|
      log_error(error)
      redirect_to login_path(url: request.fullpath)
    end

    rescue_from Framework::Errors::PatronApiError do |error|
      log_error(error)
      render "errors/patron_api_error", status: :service_unavailable
    end
  end

  private

  def log_error(error)
    logger.error("Exception: #{error.inspect}, Cause: #{error.cause.inspect}")
  end
end
