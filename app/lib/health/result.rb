module Health
  # Encapsulates a health check result
  class Result
    attr_reader :status
    attr_reader :output

    def initialize(status:, output: nil)
      @status = status
      @output = output
    end

    def as_json(*)
      json = { status: status.as_json }
      json[:output] = output if output
      json
    end

    class << self
      def pass
        Result.new(status: Status::PASS)
      end

      def warn(output)
        Result.new(status: Status::WARN, output: output)
      end
    end
  end
end
