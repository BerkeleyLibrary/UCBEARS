module HealthChecks
  class IiifServerCheck < OkComputer::Check
    include BerkeleyLibrary::Logging

    def check
      result = validate_iiif_server
      mark_message result[:message]
      mark_failure if result[:warning]
    rescue StandardError => e
      logger.error(e)
      mark_message "#{e.class}: #{e.message}"
      mark_failure
    end

    private

    def iiif_connection
      @iiif_connection ||= Faraday.new do |f|
        f.options.open_timeout = 2
        f.options.timeout = 3
      end
    end

    def iiif_test_uri
      base_uri = Lending::Config.iiif_base_uri
      return unless base_uri

      item = Item.active.first || Item.inactive.first
      return unless item

      BerkeleyLibrary::Util::URIs.append(
        base_uri,
        item.iiif_directory.first_image_url_path,
        'info.json'
      )
    end

    # Returns a hash with :message and :warning keys
    def validate_iiif_server
      test_uri = iiif_test_uri
      return { message: 'Unable to construct test image URI', warning: true } unless test_uri

      response = iiif_connection.head(test_uri)
      return { message: "HEAD #{test_uri} returned status #{response.status}", warning: true } unless response.success?

      acao_header = response.headers['Access-Control-Allow-Origin']
      return { message: "HEAD #{test_uri} missing Access-Control-Allow-Origin header", warning: true } if acao_header.blank?

      { message: 'IIIF server reachable', warning: false }
    end
  end
end
