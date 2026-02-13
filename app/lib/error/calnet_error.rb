module Error
  # Raised calnet error when it returns an unexpected response,
  # e.g. missing email value because of the schema attribute name changed unexpected by Calnet from 'berkeleyEduAlternateId' to 'berkeleyEduAlternateID' .
  class CalnetError < ApplicationError
  end
end
