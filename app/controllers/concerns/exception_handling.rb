# TODO: use a dynamic error controller so we can rescue from things like RoutingError
#       see http://web.archive.org/web/20141231234828/http://wearestac.com/blog/dynamic-error-pages-in-rails
module ExceptionHandling
  extend ActiveSupport::Concern

  # rubocop:disable Metrics/BlockLength
  included do
    extend ClassMethods

    # Order exceptions from most generic to most specific.

    rescue_from StandardError do |error|
      log_error(error)
      render :standard_error, status: :internal_server_error, locals: { exception: error }
    end

    # NOTE: Ordinarily this is never reached (and seems to be unreachable in tests),
    # but it's needed when Mirador (1) fails to find a message localization JSON file,
    # and then (2) fails to find its expected 404 template. TODO: Sort this out
    rescue_from ActionController::RoutingError, with: :handle_not_found

    rescue_from ActiveRecord::RecordNotFound, with: :handle_not_found

    rescue_from Error::PatronApiError do |error|
      log_error(error)
      render :patron_api_error, status: :service_unavailable
    end

    rescue_from Error::PatronNotFoundError do |error|
      log_error(error)
      render :patron_not_found_error, status: :forbidden, locals: { exception: error }
    end

    rescue_from Error::ForbiddenError do |error|
      log_error(error)
      render :forbidden, status: :forbidden, locals: { exception: error }
    end

    rescue_from Error::PatronNotEligibleError do |error|
      log_error(error)
      @error = error # so view has access
      render :patron_not_eligible_error, status: :forbidden, locals: { exception: error }
    end

    rescue_from Error::PatronBlockedError do |error|
      log_error(error)
      render :blocked, status: :forbidden, locals: { exception: error }
    end

    rescue_from Error::UnauthorizedError do |error|
      # this isn't really an error condition, it just means the user's
      # not logged in, so we don't need the full stack trace etc.
      logger.info(error)
      redirect_to login_path(url: request.fullpath)
    end

    def handle_not_found(error)
      log_error(error)
      render :not_found, status: :not_found, locals: { exception: error }
    end
  end
  # rubocop:enable Metrics/BlockLength

  module ClassMethods
    # Removes the handler for the specified exception class.
    #
    # @param klass [String, Class] an exception class object, or its name
    # @return [Array(String, Proc), Array(String, Symbol)] an Array of length 2, containing:
    #     1. the name of the exception class to be rescued
    #     2. a Proc, or the name of a method to call, to rescue it with
    def remove_rescue_handler_for(klass)
      return unless (key = handler_key_for(klass))
      return unless (index = rescue_handlers.find_index { |k, _| k == key })

      rescue_handlers[index].tap do
        rescue_handlers.delete_at(index)
      end
    end

    # Inserts the specified handler into the list of handlers for this Rescuable.
    #
    # See {https://api.rubyonrails.org/classes/ActiveSupport/Rescuable/ClassMethods.html#method-i-rescue_from Rescuable#rescue_from}.
    #
    # @param handler [Array(String, Proc), Array(String, Symbol)] an Array of length 2, containing:
    #   1. the name of the exception class to be rescued
    #   2. a Proc, or the name of a method to call, to rescue it with
    # @param index [Integer] an optional insert index
    def restore_rescue_handler(handler, index: 0)
      rescue_handlers.insert(index, handler)
    end

    private

    def handler_key_for(klass)
      return klass if klass.is_a?(String)
      return klass.name if klass.is_a?(Module) && klass.respond_to?(:===)
    end
  end
end
