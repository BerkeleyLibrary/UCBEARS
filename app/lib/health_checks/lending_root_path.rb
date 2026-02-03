module HealthChecks
  class LendingRootPath < OkComputer::Check
    include BerkeleyLibrary::Logging

    def check
      result = validate_lending_root
      mark_message result[:message]
      mark_failure if result[:failure]
    rescue StandardError => e
      logger.error(e)
      mark_message "Error: #{e.class.name}"
      mark_failure
    end

    private

    def lending_root
      @lending_root ||= Lending::Config.lending_root_path
    end

    # Returns a hash with :message and :failure keys
    def validate_lending_root
      return { message: 'Lending root path not set', failure: true } unless lending_root
      return { message: "Not a pathname: #{lending_root.inspect}", failure: true } unless lending_root.is_a?(Pathname)
      return { message: "Not a directory: #{lending_root}", failure: true } unless lending_root.directory?
      return { message: "Directory not readable: #{lending_root}", failure: true } unless lending_root.readable?

      { message: 'Lending root path exists and is readable', failure: false }
    end
  end
end
