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
    STOP_FILE = 'collector.stop'.freeze

    # ------------------------------------------------------------
    # Fields

    attr_reader :lending_root, :stage_roots, :interval

    # ------------------------------------------------------------
    # Initializer

    def initialize(lending_root, interval)
      @interval = ensure_valid_interval(interval)
      @lending_root = PathUtils.ensure_dirpath(lending_root)
      @stage_roots = STAGES.each_with_object({}) { |stage, roots| roots[stage] = ensure_root(stage) }
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
      logger.info("#{self}: starting for lending_root: #{lending_root}, interval: #{interval}s")
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
      interval.tap do |v|
        raise ArgumentError, "Expected sleep interval in seconds, got #{v.inspect}" unless v.is_a?(Numeric)
        raise ArgumentError, "Expected non-negative sleep interval in seconds, got #{v.inspect}" unless v > 0
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

      logger.info("#{self}: #{stop_reason}")
      exit(true)
    end

    def stop_reason
      stop_file_path.exist? ? "stop file #{stop_file_path} found; exiting" : 'stopped'
    end

    def stop_file_path
      lending_root.join(STOP_FILE)
    end

    # ------------------------------
    # Processing logic

    def process_next_or_sleep
      if (ready_dir = next_ready_dir)
        processing_dir = ensure_stage_dir(ready_dir, :processing)
        return process(ready_dir, processing_dir)
      end

      logger.info("#{self}: nothing ready to process; sleeping for #{interval} seconds")
      sleep(interval)
    end

    def process(ready_dir, processing_dir)
      process!(ready_dir, processing_dir)
      verify(processing_dir)

      move_to_final!(processing_dir)
    rescue StandardError => e
      raise ProcessingFailed.new(ready_dir, processing_dir, cause: e)
    end

    def process!(ready_dir, processing_dir)
      logger.info("#{self}: processing #{ready_dir} to #{processing_dir}")
      Processor.new(ready_dir, processing_dir).process!
    end

    def verify(processing_dir)
      # TODO: something more sophisticated
      manifest = IIIFManifest.new(processing_dir)
      raise ArgumentError, "Manifest template not present in processing directory #{processing_dir}" unless manifest.has_template?
    end

    def move_to_final!(processing_dir)
      final_dir = stage_dir(processing_dir, :final)
      logger.info("#{self}: moving #{processing_dir} to #{final_dir}")
      processing_dir.rename(final_dir)
    end

    # ------------------------------
    # Directory lookups

    # Returns the next ready directory with no corresponding processing or final
    # directory
    #
    # @return [Pathname, nil] the next ready directory, or nil if non exists
    def next_ready_dir
      ready_directories.find do |dir|
        %i[processing final].none? { |stage| stage_dir(dir, stage).exist? }
      end
    end

    # The ready directories, in order from oldest to newest
    # @return [Array<Pathname>] the ready directories, in order from oldest to newest
    def ready_directories
      stage_root = stage_root(:ready)
      stage_root.children.select { |p| p.to_s =~ PathUtils::DIRNAME_RE }.sort_by(&:mtime)
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
