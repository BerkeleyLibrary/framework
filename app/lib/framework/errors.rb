module Framework
  module Errors
    # Base class for all errors in the framework.
    class FrameworkError < StandardError; end

    # Raised when an unauthenticated request is made to a protected resource.
    class NotAuthenticatedError < FrameworkError; end

    # Raised when an error occurs contacting the Patron API.
    class PatronApiError < FrameworkError; end
  end
end
