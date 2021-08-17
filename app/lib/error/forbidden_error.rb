module Error
  # Raised when an authenticated user attempts an unauthorized actions
  class ForbiddenError < ApplicationError
  end
end
