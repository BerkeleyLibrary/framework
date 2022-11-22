module Error
  # Raised when a Patron API lookup returns no data, or
  # the patron's password is incorrect
  class PatronNotFoundError < PatronApiError
  end
end
