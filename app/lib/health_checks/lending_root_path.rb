module HealthChecks
  class LendingRootPath < OkComputer::Check
    include BerkeleyLibrary::Logging

    def check
      result = validate_lending_root
      mark_message result[:message]
      mark_failure if result[:warning]
    rescue StandardError => e
      logger.error(e)
      mark_message "#{e.class}: #{e.message}"
      mark_failure
    end

    private

    def lending_root
      @lending_root ||= Lending::Config.lending_root_path
    end

    # Returns a hash with :message and :warning keys
    def validate_lending_root
      return { message: 'Lending root path not set', warning: true } unless lending_root
      return { message: "Not a pathname: #{lending_root.inspect}", warning: true } unless lending_root.is_a?(Pathname)
      return { message: "Not a directory: #{lending_root}", warning: true } unless lending_root.directory?
      return { message: "Directory not readable: #{lending_root}", warning: true } unless lending_root.readable?

      { message: 'Lending root path exists and is readable', warning: false }
    end
  end
end
