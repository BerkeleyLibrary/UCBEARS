require 'typesafe_enum'

module Health
  # Enumerated list of health states
  class Status < TypesafeEnum::Base
    new :PASS # NOTE: states should be ordered from least to most severe
    new :WARN

    # Concatenates health states, returning the more severe state.
    # @return [Status] the more severe status
    def &(other)
      return self unless other

      self >= other ? self : other
    end

    # Returns the status as a string, suitable for use as a JSON value.
    # @return [String] the name of the status, in lower case
    def as_json(*)
      value.downcase
    end
  end
end
