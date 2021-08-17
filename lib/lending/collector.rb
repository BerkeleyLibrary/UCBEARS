require 'ucblit/logging'
require 'lending/path_utils'
require 'lending/processor'
require 'lending/iiif_manifest'

module Lending
  class Collector
    include UCBLIT::Logging

    # ------------------------------------------------------------
    # Constants

    STAGES = %i[ready processing final].freeze
    ENV_STOP_FILE = 'LIT_LENDING_COLLECTOR_STOP_FILE'.freeze

    # ------------------------------------------------------------
    # Fields

    attr_reader :lending_root, :stage_roots, :stop_file_path

    # ------------------------------------------------------------
    # Initializer

    def initialize(lending_root:, stop_file:)
      @lending_root = PathUtils.ensure_dirpath(lending_root)
      @stage_roots = STAGES.each_with_object({}) { |stage, roots| roots[stage] = ensure_root(stage) }
      @stop_file_path = @lending_root.join(stop_file)
    end

    # ------------------------------------------------------------
    # Class methods

    class << self
      def from_environment
        Collector.new(
          lending_root: ensure_env(Lending::ENV_ROOT),
          stop_file: ensure_env(ENV_STOP_FILE)
        )
      end

      private

      def ensure_env(v)
        ENV[v].tap { |value| raise ArgumentError, "$#{v} is unset or blank" if value.blank? }
      end
    end

    # ------------------------------------------------------------
    # Instance methods

    def stop!
      @stopped = true
    end

    def stopped?
      @stopped || stop_file_path.exist?
    end

    def collect!
      logger.info("#{self}: starting for lending_root: #{lending_root}, stop_file: #{stop_file_path}")
      process_until_stopped
      logger.info("#{self}: #{exit_reason}")
    rescue StandardError => e
      logger.error("#{self}: exiting due to error", e)
    end

    def to_s
      @s ||= "#{self.class.name.split('::').last}@#{object_id}"
    end

    # ------------------------------------------------------------
    # Private methods

    private

    # ------------------------------
    # Initialization validators

    # @return [Pathname]
    def ensure_root(stage)
      stage_dir_path = lending_root.join(stage.to_s)
      PathUtils.ensure_dirpath(stage_dir_path)
    end

    # ------------------------------
    # Stop logic

    def exit_reason
      return 'nothing left to process' unless stopped?

      stop_file_path.exist? ? "stop file #{stop_file_path} found" : 'stopped'
    end

    # ------------------------------
    # Processing logic

    def process_until_stopped
      ready_dirs.each do |ready_dir|
        break if stopped?

        processing_dir = ensure_stage_dir(ready_dir, :processing)
        process(ready_dir, processing_dir)
      rescue ProcessingFailed => e
        logger.error("#{self}: #{e}", e)
      end
    end

    def process(ready_dir, processing_dir)
      logger.info("#{self}: processing #{ready_dir} to #{processing_dir}")
      processor = Processor.new(ready_dir, processing_dir)
      processor.process!
      move_to_final!(processing_dir)
    rescue StandardError => e
      raise ProcessingFailed.new(ready_dir, processing_dir, cause: e)
    end

    def move_to_final!(processing_dir)
      final_dir = stage_dir(processing_dir, :final)
      logger.info("#{self}: moving #{processing_dir} to #{final_dir}")
      processing_dir.rename(final_dir)
    end

    # ------------------------------
    # Directory lookups

    # Returns all ready directories with no corresponding processing or final
    # directory, in order from oldest to newest
    #
    # @return [Array<Pathname>] an array of all ready directories
    def ready_dirs
      downstream_stages = %i[processing final]
      PathUtils.all_item_dirs(stage_root(:ready))
        .reject { |rdir| downstream_stages.any? { |stage| stage_dir(rdir, stage).exist? } }
        .sort_by(&:mtime)
    end

    # Returns the root directory for the specified stage
    # @return [Pathname] the root directory
    def stage_root(stage)
      stage_roots[stage] # stage_roots is populated in #initialize
    end

    # Returns the item directory for the specified stage
    # @return [Pathname] The item directory for the stage
    def stage_dir(item_dir, stage)
      stage_root(stage).join(item_dir.basename)
    end

    # Returns the stage directory for the specified item, first creating
    # the directory if it does not exist
    #
    # @return [Pathname]
    def ensure_stage_dir(item_dir, stage)
      stage_dir(item_dir, stage).tap { |dir| dir.mkdir unless dir.directory? }
    end

  end
end
