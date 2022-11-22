module Error
  # Raised when a patron is not an authorized proxy user
  class PatronNotProxyUserError < PatronApiError
  end
end
