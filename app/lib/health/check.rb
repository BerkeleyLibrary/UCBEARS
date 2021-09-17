module Health

  # Checks on the health of critical application dependencies
  #
  # @see https://tools.ietf.org/id/draft-inadarei-api-health-check-01.html JSON Format
  # @see https://www.consul.io/docs/agent/checks.html StatusCode based on Consul
  class Check
    include ActiveModel::Validations
    include BerkeleyLibrary::Logging

    # ############################################################
    # Constants

    ERR_IMG_SERVER_UNREACHABLE = 'Error contacting image server'.freeze
    ERR_NO_COMPLETE_ITEM = 'Unable to locate complete item'.freeze
    ERR_NO_IIIF_TEST_URI = 'Unable to construct IIIF test URI'.freeze

    # ############################################################
    # Public methods

    # ##############################
    # Validations

    # TODO: DRY these
    # TODO: toss ActiveModel, use hierarchical status methods

    VALIDATION_METHODS = %i[no_pending_migrations iiif_base_uri lending_root_path iiif_server_reachable].freeze

    VALIDATION_METHODS.each { |m| validate(m) }

    def no_pending_migrations
      ActiveRecord::Migration.check_pending!
      @no_pending_migrations = true
    rescue ActiveRecord::PendingMigrationError => e
      log_error(:no_pending_migrations, e)
      @no_pending_migrations = false
    end

    def iiif_base_uri
      return @iiif_base_uri if instance_variable_defined?(:@iiif_base_uri)

      @iiif_base_uri = Lending::Config.iiif_base_uri
    rescue Lending::ConfigException => e
      log_error(:iiif_base_uri, e)
      @iiif_base_uri = nil
    end

    def lending_root_path
      return @lending_root_path if instance_variable_defined?(:@lending_root_path)

      @lending_root_path = Lending::Config.lending_root_path
    rescue Lending::ConfigException => e
      log_error(:lending_root_path, e)
      @lending_root_path = nil
    end

    # TODO: could we simplify this check with a newer version of iipsrv?
    #       see https://github.com/ruven/iipsrv/issues/190
    def iiif_server_reachable
      return @iiif_server_reachable if instance_variable_defined?(:@iiif_server_reachable)

      @iiif_server_reachable = iiif_server_reached
    rescue StandardError => e
      log_error(:iiif_server_reachable, e, detail: ERR_IMG_SERVER_UNREACHABLE)
      @iiif_server_reachable = false
    ensure
      ensure_error_added(:iiif_server_reachable, ERR_IMG_SERVER_UNREACHABLE) unless @iiif_server_reachable
    end

    # ##############################
    # Accessors

    def result
      @result ||= passing? ? Result.pass(details) : Result.warn(details)
    end

    # ############################################################
    # Private methods

    private

    # ##############################
    # Misc. private methods

    def log_error(attr, e, detail: nil)
      logger.error(e)
      msg = [e.class, e.message.to_s.strip].join(': ')
      errors.add(attr, detail ? "#{detail}: #{msg}" : msg)
    end

    # TODO: DRY all of these
    def ensure_error_added(attr, msg_default)
      (errors.add(attr, msg_default) unless errors.key?(attr))
    end

    # ##############################
    # Private accessors

    def details
      error_hash = errors.to_h
      {}.tap do |details|
        Health::Check::VALIDATION_METHODS.each do |check|
          errs = error_hash.delete(check)
          details[check] = errs ? Result.warn(errs) : Result.pass
        end
        error_hash.each { |check, errs| details[check] = Result.warn(errs) }
      end
    end

    def active_item
      return @active_item if instance_variable_defined?(:@active_item)

      @active_item = LendingItem.active.first
    end

    def inactive_item
      return @inactive_item if instance_variable_defined?(:@inactive_item)

      @inactive_item = LendingItem.inactive.first
    end

    # Cached validation status so we only validate once
    def passing?
      @passing ||= valid?
    end

    # ##############################
    # Sub-validations

    def complete_item
      return @complete_item if instance_variable_defined?(:@complete_item)

      @complete_item = active_item || inactive_item
    end

    def iiif_test_uri
      return @iiif_test_uri if instance_variable_defined?(:@iiif_test_uri)

      @iiif_test_uri = find_iiif_test_uri
    end

    def find_iiif_test_uri
      return unless (base_uri = iiif_base_uri)
      return unless (item = complete_item)

      image_file_name = Dir.entries(item.iiif_dir).find { |e| Lending::Page.page_image?(e) }
      raise Errno::ENOENT, "No page images found in #{item.iiif_dir}" unless image_file_name # NOTE: should never happen

      BerkeleyLibrary::Util::URIs.append(base_uri, item.directory, image_file_name, 'info.json')
    end

    def iiif_server_reached
      return unless (test_uri = iiif_test_uri)

      response = Faraday.head(test_uri)

      f_successful = response.success?
      errors.add(:iiif_server_reachable, "HEAD #{iiif_test_uri} returned status #{response.status}") unless f_successful

      acao_header = response.headers['Access-Control-Allow-Origin']
      errors.add(:iiif_server_reachable, "HEAD #{iiif_test_uri} did not return Access-Control-Allow-Origin header") unless acao_header.present?

      f_successful && acao_header.present?
    end

  end
end
