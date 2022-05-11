# TODO: use a dynamic error controller so we can rescue from things like RoutingError
#       see http://web.archive.org/web/20141231234828/http://wearestac.com/blog/dynamic-error-pages-in-rails
module ExceptionHandling
  extend ActiveSupport::Concern

  included do
    # Order exceptions from most generic to most specific.

    rescue_from StandardError do |error|
      logger.error(error)
      render_error(error)
    end

    rescue_from Error::ForbiddenError do |error|
      logger.error(error)
      ensure_formats!
      render_error(error, status: :forbidden, template: :forbidden)
    end

    rescue_from Error::UnauthorizedError do |error|
      # this isn't really an error condition, it just means the user's
      # not logged in, so we don't need the full stack trace etc.
      logger.info(error.to_s)
      respond_to do |format|
        format.any(:html, :csv) do
          response.content_type = 'text/html' # TODO: shouldn't be needed in Rails 7
          redirect_to login_path(url: request.fullpath)
        end
        format.json { render_error(error, status: :unauthorized) }
      end
    end

    rescue_from(ActionController::ParameterMissing, ActionController::BadRequest) do |error|
      logger.warn(error.to_s)
      render_error(error, status: :bad_request)
    end

    # TODO: Figure out why Mirador triggers RoutingErrors
    rescue_from(ActiveRecord::RecordNotFound, ActionController::RoutingError, with: :handle_not_found)
  end

  # ------------------------------------------------------------
  # Private methods

  private

  def handle_not_found(error)
    logger.error(error)

    ensure_formats!

    respond_to do |format|
      # TODO: detect missing JSON templates & fall back to :standard_error
      format.html { render_error(error, status: :not_found, template: :not_found) }
      format.json { render_error(error, status: :not_found) }
    end
  end

  def render_error(error, status: :internal_server_error, message: error.message, template: :standard_error)
    return head(status) if formats.include?(:csv)

    locals = { status: status, exception: error, message: message }
    render(template, status: status, locals: locals)
  end

  # Formats are set in `ActionController::Rendering#process_action`; when a request
  # happens in e.g. a `before` hook, they aren't set properly yet, so we set them here.
  # @see https://stackoverflow.com/a/31673280/27358
  def ensure_formats!
    self.formats = request.formats.map(&:ref)
  end
end
