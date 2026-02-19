module HealthChecks
  class IIIFServerCheck < OkComputer::Check
    include BerkeleyLibrary::Logging

    def check
      result = perform_request
      mark_message result[:message]
      mark_failure if result[:failure]
    rescue StandardError => e
      logger.error(e)
      mark_message e.class.name
      mark_failure
    end

    private

    def iiif_connection
      @iiif_connection ||= Faraday.new do |f|
        f.options.open_timeout = 2
        f.options.timeout = 3
      end
    end

    def iiif_base_uri
      @iiif_base_uri ||= begin
        base_uri = Lending::Config.iiif_base_uri
        base_uri
      end
    end

    def iiif_test_uri
      @iiif_test_uri ||= (URI.join(iiif_base_uri, '/health') if iiif_base_uri)
    end

    # Returns a hash with :message, :failure, and :rsp keys
    def perform_request
      return { message: 'Unable to construct healthcheck URI', failure: true, rsp: nil } unless iiif_test_uri

      response = iiif_connection.get(iiif_test_uri)
      return { message: "GET #{iiif_test_uri} returned status #{response.status}", failure: true, rsp: response } unless response.success?

      { message: 'HTTP check successful', failure: false, rsp: response }
    end
  end
end
