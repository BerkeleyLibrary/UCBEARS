module Health

  # Checks on the health of critical application dependencies
  #
  # @see https://tools.ietf.org/id/draft-inadarei-api-health-check-01.html JSON Format
  # @see https://www.consul.io/docs/agent/checks.html StatusCode based on Consul
  #
  # @todo We could improve on this by adding a few additional checks, namely:
  #   - That we can actually send emails
  #   - That we can add notes to patrons (SSH access to the millennium scripts)
  class Check

    TEST_PATRON_ID = '012158720'.freeze

    attr_reader :status
    attr_reader :details

    def initialize
      status = Status::PASS
      details = {}
      all_checks.each do |name, check_method|
        result = check_method.call
        details[name] = result.as_json
        status &= result.status
      end

      @status = status
      @details = details
    end

    def as_json(*)
      { status: status, details: details }
    end

    def http_status_code
      passing? ? 200 : 429
    end

    private

    def all_checks
      { 'patron_api:find' => method(:try_find_patron) }
    end

    def passing?
      status == Status::PASS
    end

    def try_find_patron
      Patron::Record.find(TEST_PATRON_ID)
      Result.pass
    rescue StandardError => e
      Result.warn(e.class.name)
    end

  end
end
