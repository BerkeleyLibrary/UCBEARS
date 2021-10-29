require 'active_support/inflector'
require 'capybara/rspec'
require 'selenium-webdriver'
require 'berkeley_library/logging'
require 'docker'

require 'rails_helper'

module CapybaraHelper
  # Capybara artifact path
  # (see https://www.rubydoc.info/github/jnicklas/capybara/Capybara.configure)
  #
  # NOTE: Rails' system test helpers insist on writing screenshots to
  #       `tmp/screenshots` regardless of Capybara configuration:
  #       see https://github.com/rails/rails/issues/41828.
  #
  #       In the Docker image we symlink that to `artifacts/screenshots`.
  SAVE_PATH = 'artifacts/capybara'.freeze

  class << self
    def configure!
      configurator = Docker.running_in_container? ? GridConfigurator.new : LocalConfigurator.new
      configurator.configure!
    end

    def print_javascript_log(msg = nil, out = $stderr)
      out.write("#{msg}: #{formatted_javascript_log}\n")
    end

    def browser_project_root
      Docker.running_in_container? ? '/build' : Rails.root
    end

    def local_save_path
      File.join(Rails.root, SAVE_PATH)
    end

    def browser_save_path
      File.join(browser_project_root, SAVE_PATH)
    end

    def delete_all_cookies
      browser.tap do |b|
        next unless b.respond_to?(:manage)
        next unless (manager = b.manage).respond_to?(:delete_all_cookies)

        manager.delete_all_cookies
      end
    end

    def active_element
      return unless browser
      return unless browser.respond_to?(:switch_to)

      browser.switch_to.active_element
    end

    private

    def browser
      Capybara.current_session.driver.browser
    end

    def formatted_javascript_log(indent = '  ')
      logs = browser.manage.logs.get(:browser)
      return 'No entries logged to JavaScript console' if logs.nil? || logs.empty?

      StringIO.new.tap do |out|
        out.write("#{logs.size} entries logged to JavaScript console:\n")
        logs.each_with_index { |entry, i| out.write("#{indent}#{i}\t#{entry}\n") }
      end.string
    end
  end

  class Configurator
    include BerkeleyLibrary::Logging

    DEFAULT_CHROME_ARGS = ['--window-size=2560,1344'].freeze

    DEFAULT_WEBMOCK_OPTIONS = {
      allow_localhost: true,
      # prevent running out of file handles -- see https://github.com/teamcapybara/capybara#gotchas
      net_http_connect_on_start: true
    }.freeze

    attr_reader :driver_name
    attr_reader :chrome_args
    attr_reader :chrome_prefs
    attr_reader :webmock_options
    attr_reader :driver_opts

    def initialize(driver_name, chrome_args: [], chrome_prefs: {}, webmock_options: {}, driver_opts: {})
      @driver_name = driver_name
      @chrome_args = DEFAULT_CHROME_ARGS + chrome_args
      @chrome_prefs = Configurator.default_chrome_prefs.merge(chrome_prefs)
      @webmock_options = merge_webmock_options(webmock_options)
      @driver_opts = driver_opts
    end

    def configure!
      logger.debug("#{self.class}: configuring Capybara")
      configure_capybara!
      configure_rspec!
    end

    class << self
      def default_chrome_prefs
        {
          'download.prompt_for_download' => false,
          'download.default_directory' => CapybaraHelper.browser_save_path
        }
      end
    end

    def configure_capybara!
      Capybara.save_path = CapybaraHelper.local_save_path.tap do |p|
        FileUtils.mkdir_p(p)
      end

      Capybara.register_driver(driver_name) do |app|
        capabilities = [
          ::Selenium::WebDriver::Chrome::Options.new(args: chrome_args, prefs: chrome_prefs),
          ::Selenium::WebDriver::Remote::Capabilities.chrome(
            'goog:loggingPrefs' => {
              browser: 'ALL', driver: 'ALL'
            }
          )
        ]
        options = { capabilities: capabilities }.merge(driver_opts)
        Capybara::Selenium::Driver.new(app, options)
      end

      Capybara.javascript_driver = driver_name
    end

    private

    def merge_webmock_options(webmock_options)
      DEFAULT_WEBMOCK_OPTIONS.dup.tap do |opts|
        webmock_options.each do |opt, val|
          opts[opt] = val.is_a?(Array) ? ((opts[opt] || []) + val).uniq : val
        end
      end
    end

    def configure_rspec!
      # these accessors won't be in scope when the config block is executed,
      # so we capture them as local variables
      driver_name = self.driver_name
      webmock_options = self.webmock_options

      # TODO: replace with around(:each)
      #       (see CapybaraHelper::GridConfigurator#configure!)
      RSpec.configure do |config|
        config.before(:each, type: :system) do
          driven_by(driver_name)
          WebMock.disable_net_connect!(**webmock_options)
        end

        config.after(:each, type: :system) do |example|
          next unless example.exception

          test_name = example.metadata[:full_description]
          test_source_location = example.metadata[:location]
          CapybaraHelper.print_javascript_log("#{test_name} (#{test_source_location}) failed")
        end
      end
    end
  end

  class GridConfigurator < Configurator
    CAPYBARA_APP_HOSTNAME = 'app.test'.freeze
    SELENIUM_HOSTNAME = 'selenium.test'.freeze

    # noinspection RubyLiteralArrayInspection
    GRID_CHROME_ARGS = [
      # Docker containers default to a /dev/shm too small for Chrome's cache
      '--disable-dev-shm-usage', # TODO: do we still need this?
      '--disable-gpu'
    ].freeze

    GRID_DRIVER_OPTS = {
      browser: :remote,
      url: "http://#{SELENIUM_HOSTNAME}:4444/wd/hub"
    }.freeze

    def initialize
      super(:selenium_grid, webmock_options: { allow: [SELENIUM_HOSTNAME] }, chrome_args: GRID_CHROME_ARGS, driver_opts: GRID_DRIVER_OPTS)
    end

    def configure_capybara!
      super

      Capybara.server_port = ENV['CAPYBARA_SERVER_PORT'] if ENV['CAPYBARA_SERVER_PORT']
      Capybara.app_host = "http://#{CAPYBARA_APP_HOSTNAME}"
      Capybara.server_host = '0.0.0.0'
    end
  end

  class LocalConfigurator < Configurator
    def initialize
      super(:selenium_headless, chrome_args: ['--headless'], driver_opts: { browser: :chrome })
    end
  end
end

CapybaraHelper.configure!
