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

    def collect!
      loop do
        exit_if_stopped
        process_next_or_sleep
      rescue StandardError => e
        logger.error("#{self}: exiting due to error", e)
        exit(false)
      end
    end

    def to_s
      "#<#{self.class.name.split('::'.last)}: #{lending_root}, #{interval}>"
    end

    private

    def ensure_valid_interval(interval)
      interval.tap do |v|
        raise ArgumentError, "Expected sleep interval in seconds, got #{v.inspect}" unless v.is_a?(Numeric)
        raise ArgumentError, "Expected non-negative sleep interval in seconds, got #{v.inspect}" unless v > 0
      end
    end

    def process_next_or_sleep
      if (ready_dir = next_ready_dir)
        return process(ready_dir)
      end

      logger.info("#{self}: nothing ready to process; sleeping for #{interval} seconds")
      sleep(interval)
    end

    def exit_if_stopped
      return unless stopped?

      logger.info("#{self}: #{stop_reason}")
      exit(true)
    end

    def stop_reason
      stop_file_path.exist? ? "stop file #{stop_file_path} found; exiting" : 'stopped'
    end

    def next_ready_dir
      ready_directories.find do |dir|
        %i[processing final].none? { |stage| stage_dir(dir, stage).exist? }
      end
    end

    def process(ready_dir)
      processing_dir = ensure_stage_dir(ready_dir, :processing)
      begin
        Processor.new(ready_dir, processing_dir).process!
        verify(processing_dir)

        final_dir = stage_dir(ready_dir, :final)
        processing_dir.rename(final_dir)
      rescue StandardError => e
        raise ProcessingFailed.new(ready_dir, processing_dir, cause: e)
      end
    end

    def stopped?
      @stopped || stop_file_path.exist?
    end

    def stop_file_path
      lending_root.join(STOP_FILE)
    end

    def verify(processing_dir)
      # TODO: something more sophisticated
      manifest = IIIFManifest.new(processing_dir)
      raise ArgumentError, "Manifest template not present in processing directory #{processing_dir}" unless manifest.has_template?
    end

    # @return [Pathname]
    def stage_root(stage)
      stage_roots[stage]
    end

    # @return [Pathname]
    def ensure_root(stage)
      stage_dir_path = lending_root.join(stage.to_s)
      PathUtils.ensure_dirpath(stage_dir_path)
    end

    # The ready directories, in order from oldest to newest
    # @return Array<Pathname> the ready directories, in order from oldest to newest
    def ready_directories
      item_directories(:ready)
    end

    # @return Array<Pathname> the directories for this stage, in order from oldest to newest
    def item_directories(stage)
      stage_root = stage_root(stage)
      stage_root.children.select { |p| p.to_s =~ PathUtils::DIRNAME_RE }.sort_by(&:mtime)
    end

    # @return [Pathname]
    def stage_dir(item_dir, stage)
      stage_root(stage).join(item_dir.basename)
    end

    def ensure_stage_dir(item_dir, stage)
      stage_dir(item_dir, stage).tap { |dir| dir.mkdir unless dir.directory? }
    end

  end
end
