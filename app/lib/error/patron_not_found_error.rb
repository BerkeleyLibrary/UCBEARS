module Error
  # Raised when a Patron API lookup returns no data
  class PatronNotFoundError < PatronApiError
  end
end
