module Patron
  # Represents a Millennium patron dump response.
  class Dump
    attr_reader :patron_id

    def [](key)
      data[key]
    end

    class << self
      def from_patron_api(api_base_url, patron_id)
        escaped_id = escape_patron_id(patron_id)
        uri = URI.join(api_base_url, "/PATRONAPI/#{escaped_id}/dump")
        dump_str = uri.open(ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE).read
        new(patron_id, dump_str)
      rescue OpenURI::HTTPError
        raise Error::PatronApiError
      end

      # rubocop:disable Lint/UriEscapeUnescape
      def escape_patron_id(id)
        # Using obsolete method for Millennium compatibility
        silence_warnings do
          URI.escape(id.to_s)
        end
      end
      # rubocop:enable Lint/UriEscapeUnescape

      private :new
    end

    private

    def data
      @data ||= {}
    end

    def initialize(patron_id, dump_str)
      @patron_id = patron_id

      stripped = ActionController::Base.helpers.strip_tags(dump_str)
      stripped.each_line { |line| parse_line(line) }
    end

    def parse_line(line)
      return unless (matches = line.match(%r{^(?<key>[/\w\s]+(\[.+\]+)?)=(?<val>.*)$}))

      key = matches[:key]
      val = matches[:val]
      raise to_error(val) if key == 'ERRMSG'

      data[key] = new_value(val, data[key])
    end

    def to_error(errmsg_value)
      return Error::PatronApiError.new(errmsg_value) unless errmsg_value.include?('record not found')

      Error::PatronNotFoundError.new("No patron record for '#{patron_id}'")
    end

    def new_value(value, old_value)
      return value unless old_value
      return [old_value, value] unless old_value.is_a?(Array)

      old_value << value
    end
  end
end
