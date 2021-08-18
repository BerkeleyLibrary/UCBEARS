# TODO: use a dynamic error controller so we can rescue from things like RoutingError
#       see http://web.archive.org/web/20141231234828/http://wearestac.com/blog/dynamic-error-pages-in-rails
module ExceptionHandling
  extend ActiveSupport::Concern

  included do
    # Order exceptions from most generic to most specific.

    # NOTE: Ordinarily this is never reached (and seems to be unreachable in tests),
    # but it's needed when Mirador (1) fails to find a message localization JSON file,
    # and then (2) fails to find its expected 404 template. TODO: Sort this out
    rescue_from ActionController::RoutingError, with: :handle_not_found

    rescue_from ActiveRecord::RecordNotFound, with: :handle_not_found

    rescue_from Error::ForbiddenError do |error|
      log_error(error)
      render :forbidden, status: :forbidden, locals: { exception: error }
    end

    rescue_from Error::UnauthorizedError do |error|
      # this isn't really an error condition, it just means the user's
      # not logged in, so we don't need the full stack trace etc.
      logger.info(error.to_s)
      redirect_to login_path(url: request.fullpath)
    end

    def handle_not_found(error)
      log_error(error)
      render :not_found, status: :not_found, locals: { exception: error }
    end
  end

end
