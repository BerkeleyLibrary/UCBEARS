class ApplicationJob < ActiveJob::Base
  MILL_DATE_FORMAT = '%Y%m%d'.freeze

  def today
    @today ||= Time.current.strftime(MILL_DATE_FORMAT)
  end

  # Log an exception
  def log_error(error)
    # TODO: share code w/ApplicationController
    msg = {
      msg: error.message,
      error: error.inspect.to_s,
      cause: error.cause.inspect.to_s
    }
    msg[:backtrace] = error.backtrace if Rails.logger.level < Logger::INFO
    logger.error(msg)
  end
end
