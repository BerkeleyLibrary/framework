module Framework
  # Namespace containing all framework error classes.
  module Errors
    # Base class for all errors in the framework.
    class FrameworkError < StandardError; end

    # Raised when an unauthenticated request is made to a protected resource.
    #
    # This is called "Unauthorized" (rather than the more accurate "Not
    # Authenticated") because that is how the HTTP Spec defines this.
    #
    # @see https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/401
    class UnauthorizedError < FrameworkError; end

    # Raised when an error occurs contacting the Patron API.
    class PatronApiError < FrameworkError; end

    # Raised if someone attempts to authenticate with an invalid provider.
    class InvalidAuthProviderError < FrameworkError; end
  end
end
