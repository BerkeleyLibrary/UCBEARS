module Health

  # Checks on the health of critical application dependencies
  #
  # @see https://tools.ietf.org/id/draft-inadarei-api-health-check-01.html JSON Format
  # @see https://www.consul.io/docs/agent/checks.html StatusCode based on Consul
  class Check
    include BerkeleyLibrary::Logging

    # ############################################################
    # Constants

    ERR_IMG_SERVER_UNREACHABLE = 'Error contacting image server'.freeze
    ERR_NO_COMPLETE_ITEM = 'Unable to locate complete item'.freeze

    # ############################################################
    # Public methods

    # ##############################
    # Validations

    # TODO: Implement 529 fail
    VALIDATION_METHODS = %i[
      no_pending_migrations
      lending_root_path
      test_item_exists
      iiif_server_reachable
    ].freeze

    def no_pending_migrations
      @no_pending_migrations ||= without_exceptions do
        ActiveRecord::Migration.check_pending!
        Result.pass
      end
    end

    def lending_root_path
      @lending_root_path ||= without_exceptions do
        readable = Lending::Config.lending_root_path
        next Result.warn('lending root path not set') unless readable
        next Result.warn("not a pathname: #{readable.inspect}") unless readable.is_a?(Pathname)
        next Result.warn("not a directory: #{readable}") unless readable.directory?
        next Result.warn("directory not readable: #{readable}") unless readable.readable?

        Result.pass
      end
    end

    def test_item_exists
      @test_item_exists ||= without_exceptions do
        complete_item.present? ? Result.pass : Result.warn(ERR_NO_COMPLETE_ITEM)
      end
    end

    def iiif_server_reachable
      @iiif_server_reachable ||= without_exceptions do
        next Result.warn('unable to construct test image URI') unless (test_uri = iiif_test_uri)

        response = Faraday.head(test_uri)
        next Result.warn("HEAD #{iiif_test_uri} returned status #{response.status}") unless response.success?

        acao_header = response.headers['Access-Control-Allow-Origin']
        next Result.warn("HEAD #{iiif_test_uri} did not return Access-Control-Allow-Origin header") unless acao_header.present?

        Result.pass
      end
    end

    # ##############################
    # Accessors

    def result
      @result ||= run_all_checks
    end

    # ############################################################
    # Private methods

    # ##############################
    # Checks

    def run_all_checks
      status = Health::Status::PASS
      details = {}.tap do |dt|
        VALIDATION_METHODS.each do |check|
          check_result = send(check)
          status &= check_result.status
          dt[check] = check_result
        end
      end
      Result.new(status: status, details: details)
    end

    def without_exceptions
      yield
    rescue StandardError => e
      logger.error(e)
      msg = [e.class, e.message.to_s.strip].join(': ')
      Result.warn(msg)
    end

    # ##############################
    # Private accessors

    def active_item
      return @active_item if instance_variable_defined?(:@active_item)

      @active_item = Item.active.first
    end

    def inactive_item
      return @inactive_item if instance_variable_defined?(:@inactive_item)

      @inactive_item = Item.inactive.first
    end

    def complete_item
      return @complete_item if instance_variable_defined?(:@complete_item)

      @complete_item = active_item || inactive_item
    end

    def iiif_test_uri
      return @iiif_test_uri if instance_variable_defined?(:@iiif_test_uri)

      @iiif_test_uri = find_iiif_test_uri
    end

    def iiif_base_uri
      return @iiif_base_uri if instance_variable_defined?(:@iiif_base_uri)

      @iiif_base_uri = Lending::Config.iiif_base_uri
    end

    # ##############################
    # Validation prerequisites

    # TODO: could we simplify this check with a newer version of iipsrv?
    #       see https://github.com/ruven/iipsrv/issues/190
    def find_iiif_test_uri
      return unless (base_uri = iiif_base_uri)
      return unless (item = complete_item)

      iiif_directory = item.iiif_directory
      BerkeleyLibrary::Util::URIs.append(base_uri, iiif_directory.first_image_url_path, 'info.json')
    end

  end
end
