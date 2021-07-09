require 'rails_helper'
require 'concurrent-ruby'
require 'lending'

module Lending
  describe Collector do
    attr_reader :lending_root

    before(:each) do
      lending_root_str = Dir.mktmpdir(File.basename(__FILE__, '.rb'))
      @lending_root = Pathname.new(lending_root_str)
      Collector::STAGES.each do |stage|
        lending_root.join(stage.to_s).mkdir
      end
    end

    after(:each) do
      FileUtils.remove_dir(lending_root.to_s, true)
    end

    describe :collect do
      attr_reader :collector

      before(:each) do
        @collector = Collector.new(lending_root, 0.01)
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
        stop_file_path = lending_root.join(Collector::STOP_FILE)
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
          collector.stop!
        end

        manifest = instance_double(IIIFManifest)
        expect(IIIFManifest).to receive(:new).with(processing_dir).and_return(manifest)
        expect(manifest).to receive(:has_template?).and_return(true)

        Timeout.timeout(5) do
          collector.collect!
        rescue SystemExit => e
          expect(e.success?).to eq(true)
        end

        expect(processing_dir.exist?).to eq(false)
        expect(final_dir.exist?).to eq(true)
      end
    end
  end
end
