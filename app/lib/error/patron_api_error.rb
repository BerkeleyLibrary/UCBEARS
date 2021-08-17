module Error
  # Raised when the application couldn't connect to the patron API, e.g. due
  # to a network/firewall blockage.
  class PatronApiError < ApplicationError
  end
end
