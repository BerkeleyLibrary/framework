module Error
  # Raised when Alma returns a not-found style response.
  # Subclassing ActiveRecord::RecordNotFound preserves existing 404 handling.
  class AlmaRecordNotFoundError < ActiveRecord::RecordNotFound
  end
end
