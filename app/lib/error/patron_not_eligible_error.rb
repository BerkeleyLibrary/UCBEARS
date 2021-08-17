module Error
  # Raised to indicate a patron lacks a note authorizing access to a service
  class PatronNotEligibleError < ForbiddenError
    attr_reader :patron

    def initialize(msg, patron)
      @patron = patron
      super(msg)
    end
  end
end
