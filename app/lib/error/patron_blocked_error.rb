module Error
  # Raised when a patron has an active block
  class PatronBlockedError < ForbiddenError
  end
end
