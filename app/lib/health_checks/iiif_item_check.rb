require 'health_checks/iiif_server_check'

module HealthChecks
  class IIIFItemCheck < IIIFServerCheck

    private

    def iiif_test_uri
      @iiif_test_uri ||= begin
        item = Item.active.first || Item.inactive.first
        if item && iiif_base_uri
          BerkeleyLibrary::Util::URIs.append(
            iiif_base_uri,
            item.iiif_directory.first_image_url_path,
            'info.json'
          )
        end
      end
    end

    def perform_request
      # iipsrv won't return an CORS header for the "health" endpoint, so
      # we still call a test item to do a separate check
      response = super
      return response if response[:failure]

      acao_header = response[:rsp].headers['Access-Control-Allow-Origin']
      if acao_header.blank?
        return {
          message: "GET #{iiif_test_uri} missing Access-Control-Allow-Origin header", failure: true, rsp: response[:rsp]
        }
      end
      response
    end
  end
end
