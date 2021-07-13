require 'rails_helper'
require 'concurrent-ruby'
require 'lending'

module Lending
  describe Collector do
    attr_reader :lending_root

    let(:stem) { File.basename(__FILE__, '.rb') }

    before(:each) do
      lending_root_str = Dir.mktmpdir(stem)
      @lending_root = Pathname.new(lending_root_str)
      Collector::STAGES.each { |stage| lending_root.join(stage.to_s).mkdir }
    end

    after(:each) do
      FileUtils.remove_dir(lending_root.to_s, true)
    end

    describe(:new) do
      let(:stop_file) { "#{stem}.stop" }
      it 'requires a numeric interval' do
        expect { Collector.new(lending_root, 'not a number', stop_file) }.to raise_error(TypeError)
      end
    end

    describe :collect do
      let(:sleep_interval) { 0.01 }
      let(:stop_file) { "#{stem}.stop" }
      attr_reader :collector

      before(:each) do
        @collector = Collector.new(lending_root, sleep_interval, stop_file)
      end

      it 'exits immediately if stopped' do
        collector.stop!

        Timeout.timeout(1) do
          expect { collector.collect! }.to raise_error(SystemExit) do |err|
            expect(err.success?).to eq(true)
          end
        end
      end

      it 'stops if a stop file is present' do
        stop_file_path = collector.stop_file_path
        FileUtils.touch(stop_file_path.to_s)

        Timeout.timeout(5) do
          expect { collector.collect! }.to raise_error(SystemExit) do |err|
            expect(err.success?).to eq(true)
          end
        end
      end

      it 'processes files' do
        item_dirname = 'b12345678_c12345678'

        ready_dir = lending_root.join('ready').join(item_dirname)
        ready_dir.mkdir

        processing_dir = lending_root.join('processing').join(item_dirname)
        expect(processing_dir.exist?).to eq(false)

        final_dir = lending_root.join('final').join(item_dirname)
        expect(final_dir.exist?).to eq(false)

        processor = instance_double(Processor)
        expect(Processor).to receive(:new).with(ready_dir, processing_dir).and_return(processor)

        expect(processor).to(receive(:process!)) do
          expect(processing_dir.exist?).to eq(true)

          Thread.new do
            sleep(2 * sleep_interval)
            collector.stop!
          end
        end

        manifest = instance_double(IIIFManifest)
        expect(IIIFManifest).to receive(:new).with(processing_dir).and_return(manifest)
        expect(manifest).to receive(:has_template?).and_return(true)

        # allow(UCBLIT::Logging.logger).to receive(:info) do |msg|
        #   $stderr.puts("#{Time.current.strftime('%H:%M:%S:%S.%6N')} #{msg}")
        # end

        expect(UCBLIT::Logging.logger).to receive(:info).with(/starting/).ordered
        expect(UCBLIT::Logging.logger).to receive(:info).with(/processing/).ordered
        expect(UCBLIT::Logging.logger).to receive(:info).with(/moving/).ordered
        expect(UCBLIT::Logging.logger).to receive(:info).with(/nothing ready to process; sleeping/).at_least(:once).ordered
        expect(UCBLIT::Logging.logger).to receive(:info).with(/stopped/).ordered

        Timeout.timeout(5) do
          collector.collect!
        rescue SystemExit => e
          expect(e.success?).to eq(true)
        end

        expect(processing_dir.exist?).to eq(false)
        expect(final_dir.exist?).to eq(true)

        expect(collector.stopped?).to eq(true)
      end

      it 'exits in the event of an error' do
        item_dirname = 'b12345678_c12345678'

        ready_dir = lending_root.join('ready').join(item_dirname)
        ready_dir.mkdir

        processing_dir = lending_root.join('processing').join(item_dirname)
        expect(processing_dir.exist?).to eq(false)

        processor = instance_double(Processor)
        expect(Processor).to receive(:new).with(ready_dir, processing_dir).and_return(processor)

        error_message = 'Oops'
        expect(processor).to(receive(:process!)).and_raise(error_message)

        expect(UCBLIT::Logging.logger).to receive(:info).with(/starting/).ordered
        expect(UCBLIT::Logging.logger).to receive(:info).with(/processing/).ordered
        expect(UCBLIT::Logging.logger).to receive(:error).with(/exiting due to error/, an_object_satisfying do |obj|
          obj.is_a?(Lending::ProcessingFailed)
          obj.message.include?(error_message)
        end).ordered

        Timeout.timeout(5) do
          collector.collect!
        rescue SystemExit => e
          expect(e.success?).to eq(false)
        end

        expect(processing_dir.exist?).to eq(true)

        final_dir = lending_root.join('final').join(item_dirname)
        expect(final_dir.exist?).to eq(false)

        expect(collector.stopped?).to eq(false)
      end
    end

    describe :from_environment do
      let(:env_vars) { [Lending::ENV_ROOT, Collector::ENV_INTERVAL, Collector::ENV_STOP_FILE] }

      before(:each) do
        @env_vals = env_vars.each_with_object({}) { |var, vals| vals[var] = ENV[var] }
      end

      after(:each) do
        @env_vals.each { |var, val| ENV[var] = val }
      end

      it 'reads the initialization info from the stop file' do
        Dir.mktmpdir(File.basename(__FILE__, '.rb')) do |lending_root|
          Collector::STAGES.each do |stage|
            FileUtils.mkdir(File.join(lending_root, stage.to_s))
          end

          ENV[Lending::ENV_ROOT] = lending_root
          ENV[Collector::ENV_INTERVAL] = '60'
          ENV[Collector::ENV_STOP_FILE] = 'stop.stop'

          collector = Collector.from_environment
          expect(collector.lending_root.to_s).to eq(lending_root)
          expect(collector.interval).to eq(60.0)
          expect(collector.stop_file_path.to_s).to eq(File.join(lending_root, 'stop.stop'))
        end
      end
    end
  end
end
