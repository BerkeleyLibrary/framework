# Namespace containing all framework error classes.
module Error
  # Base class for all errors in the framework.
  class BaseError < StandardError; end

  # Raised when an unauthenticated request is made to a protected resource.
  #
  # This is called "Unauthorized" (rather than the more accurate "Not
  # Authenticated") because that is how the HTTP Spec defines this.
  #
  # @see https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/401
  class UnauthorizedError < BaseError; end

  # Raised when an error occurs contacting the Patron API.
  class PatronApiError < BaseError; end

  # Raised if someone attempts to authenticate with an invalid provider.
  class InvalidAuthProviderError < BaseError; end

  # Raised if a patron has blocks
  class ForbiddenError < BaseError; end
  class PatronBlockedError < ForbiddenError; end

  #Raised for patrons who do not have access to article request form service.
  class FacultyNoteError < ForbiddenError; end
  class StudentNoteError < ForbiddenError; end
  class GeneralNoteError < ForbiddenError; end
end
