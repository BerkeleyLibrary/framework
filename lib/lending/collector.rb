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
    ENV_INTERVAL = 'LIT_LENDING_COLLECTOR_INTERVAL'.freeze
    ENV_SLEEP_FILE = 'LIT_LENDING_COLLECTOR_sleep_file'.freeze

    # ------------------------------------------------------------
    # Fields

    attr_reader :lending_root, :stage_roots, :interval, :sleep_file_path

    # ------------------------------------------------------------
    # Initializer

    def initialize(lending_root, interval, sleep_file)
      @interval = ensure_valid_interval(interval)
      @lending_root = PathUtils.ensure_dirpath(lending_root)
      @stage_roots = STAGES.each_with_object({}) { |stage, roots| roots[stage] = ensure_root(stage) }
      @sleep_file_path = @lending_root.join(sleep_file)
    end

    # ------------------------------------------------------------
    # Class methods

    class << self
      def from_environment
        args = [Lending::ENV_ROOT, ENV_INTERVAL, ENV_SLEEP_FILE].map(&method(:ensure_env))
        Collector.new(*args)
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
      @stopped || false
    end

    def collect!
      logger.info("#{self}: starting for lending_root: #{lending_root}, interval: #{interval}s, sleep_file: #{sleep_file_path}")
      loop do
        exit_if_stopped
        process_next_or_sleep
      rescue StandardError => e
        logger.error("#{self}: exiting due to error", e)
        exit(false)
      end
    end

    def to_s
      @s ||= "#{self.class.name.split('::').last}@#{object_id}"
    end

    # ------------------------------------------------------------
    # Private methods

    private

    # ------------------------------
    # Initialization validators

    def ensure_valid_interval(interval)
      (interval.is_a?(Numeric) ? interval : Float(interval)).tap do |v|
        raise ArgumentError, "Expected non-negative sleep interval in seconds, got #{interval.inspect}" unless v > 0
      end
    end

    # @return [Pathname]
    def ensure_root(stage)
      stage_dir_path = lending_root.join(stage.to_s)
      PathUtils.ensure_dirpath(stage_dir_path)
    end

    # ------------------------------
    # Stop logic

    def exit_if_stopped
      return unless stopped?

      logger.info("#{self}: stopped")
      exit(true)
    end

    # ------------------------------
    # Processing logic

    def process_next_or_sleep
      return sleep_with_msg("sleep file #{sleep_file_path} found") if sleep_file_path.exist?
      return sleep_with_msg('nothing ready to process') unless (ready_dir = next_ready_dir)

      processing_dir = ensure_stage_dir(ready_dir, :processing)
      process(ready_dir, processing_dir)
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

    def sleep_with_msg(msg)
      logger.info("#{self}: #{msg}; sleeping for #{interval} seconds")
      sleep(interval)
    end

    # ------------------------------
    # Directory lookups

    # Returns the next ready directory with no corresponding processing or final
    # directory
    #
    # @return [Pathname, nil] the next ready directory, or nil if non exists
    def next_ready_dir
      downstream_stages = %i[processing final]
      ready_directories.find do |rdir|
        downstream_stage = downstream_stages.find { |stage| stage_dir(rdir, stage).exist? }
        downstream_stage.nil?.tap do |not_found|
          msg = not_found ? "has no downstream directories; returning #{rdir}" : "#{downstream_stage} directory already exists; skipping #{rdir}"
          logger.debug("#{self}: #{rdir.basename} " + msg)
        end
      end
    end

    # The ready directories, in order from oldest to newest
    # @return [Array<Pathname>] the ready directories, in order from oldest to newest
    def ready_directories
      PathUtils.all_item_dirs(stage_root(:ready)).sort_by(&:mtime)
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
