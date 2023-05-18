module Health
  # Encapsulates a health check result
  class Result
    attr_reader :status
    attr_reader :details

    def initialize(status:, details: nil)
      @status = status
      @details = details
    end

    def as_json(*)
      json = { status: status.as_json }
      json[:details] = details if details
      json
    end

    delegate :http_status, to: :status

    class << self
      def pass(details = nil)
        new(status: Status::PASS, details:)
      end

      def warn(details)
        new(status: Status::WARN, details:)
      end
    end
  end
end
