require 'rspec/core/rake_task'
require 'docker'

# TODO: convert all this to a Yarn task?
#       see https://unused.github.io/blog/posts/eslint-rails/
module BerkeleyLibrary
  class ESLintRunner
    include FileUtils

    # @return [String] the report format
    attr_reader :report_format

    # @return [String] the report path
    attr_reader :report_path

    # @return [Array<String>] the JavaScript directories to inspect
    attr_reader :js_dirs

    # @return [IO] target for ESLint stderr output
    attr_reader :err_stream

    # Initializes a new {ESLintRunner}.
    #
    # @param report_format [String] the report format
    # @param report_path [String] the report path
    # @param js_dirs [String, Array<String>] the JavaScript directory or directories to inspect
    # @param err_stream [IO, nil] target for ESLint stderr output (`nil` redirects to `File::NULL`)
    def initialize(report_format: 'html', report_path: 'artifacts/eslint/index.html', js_dirs: 'app/javascript', err_stream: nil)
      @report_format = report_format
      @report_path = report_path
      @js_dirs = Array(js_dirs)
      @err_stream = err_stream || File::NULL
    end

    class << self
      # @return [ESLintRunner] the default runner.
      def default_runner
        @default_runner ||= ESLintRunner.new(err_stream: default_err_stream)
      end

      def default_err_stream
        Docker.running_in_container? ? $stdout : nil
      end
    end

    # Writes a formatted report to {#report_path}.
    # @return [Integer] 0 for success, nonzero value for failure
    # @yieldparam exit_status [Integer] 0 for success, nonzero value for failure
    def write_report(&block)
      ensure_report_path!
      begin
        cmd = eslint_cmd("--format=#{report_format}")
        run_cmd(cmd, out: report_path, &block)
      ensure
        warn("ESLint report written to #{report_path}") if File.file?(report_path)
      end
    end

    # Writes a report to the console.
    # @param silence_errors [Boolean] whether to warn when the eslint command returns a nonzero exit status.
    # @return [Integer] 0 for success, nonzero value for failure
    # @yieldparam exit_status [Integer] 0 for success, nonzero value for failure
    def write_to_console(silence_errors: true, &block)
      run_cmd(eslint_cmd, silence_errors: silence_errors, &block)
    end

    # Fixes any detected problems that can be auto-fixed.
    # @return [Integer] 0 for success, nonzero value for failure
    # @yieldparam exit_status [Integer] 0 for success, nonzero value for failure
    def fix(&block)
      cmd = eslint_cmd('--fix')
      run_cmd(cmd, &block)
    end

    private

    def ensure_report_path!
      report_path.tap do |p|
        FileUtils.rm(p) if File.exist?(p)
        report_dir = File.dirname(p)
        FileUtils.mkdir_p(report_dir) unless File.directory?(report_dir)
      end
    end

    def eslint_cmd(*args)
      %w[yarn eslint].tap do |cmd|
        cmd.concat(args)
        cmd.concat(js_dirs)
      end
    end

    # TODO: figure out how to silence "npm ERR!" but still get $stderr output
    def run_cmd(cmd, out: $stdout, err: err_stream, silence_errors: false)
      sh(*cmd, out: out, err: err) do |ok, ps|
        ps.exitstatus.tap do |exit_status|
          puts("`#{cmd.shelljoin}` returned exit status #{exit_status}") unless ok || silence_errors
          yield exit_status if block_given?
        end
      end
    end
  end
end

namespace :js do

  desc 'check JavaScript syntax, find problems, and enforce code style'
  task eslint: ['yarn:install'] do
    runner = BerkeleyLibrary::ESLintRunner.default_runner
    runner.write_report do |exit_status|
      next if exit_status == 0

      runner.write_to_console
      exit(exit_status)
    end

    puts 'No problems found'
  end

  desc 'Automatically fix problems detected by ESLint'
  namespace :eslint do
    task fix: ['yarn:install'] do
      runner = BerkeleyLibrary::ESLintRunner.default_runner
      runner.fix do |exit_status|
        next if exit_status == 0

        puts 'Not all problems could be fixed; see above for details'
        exit(exit_status)
      end

      puts 'All problems fixed (or no problems to begin with)'
    end
  end
end
