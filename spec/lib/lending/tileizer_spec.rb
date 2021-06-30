require 'rails_helper'
require 'lending'

module Lending
  describe Tileizer do
    let(:samples) { 'spec/data/lending/samples/b135297126_C068087930' }
    let(:indir) { 'spec/data/lending/incoming/b11996535_B 3 106 704' }
    let(:infiles) { Dir.entries(indir).select { |f| f.end_with?('.tif') }.sort }

    describe 'instance #tileize' do
      it 'tileizes to a specified file' do
        infile = File.join(samples, 'incoming/00000100.tif')
        expected = File.join(samples, 'final/00000100.tif')

        Dir.mktmpdir do |outdir|
          basename = File.basename(infile)
          outfile = File.join(outdir, basename)
          tileizer = Tileizer.new(infile, outfile)
          tileizer.tileize!
          expect(tileizer).to be_tileized

          # Note: we can't just compare files because we need to handle minor differences
          # in output across OSes and libvips/libtiff versions, so let's leverage the code
          # we already wrote to detect image tiles for IIIF manifest generation

          page_expected = Lending::Page.new(expected)
          page_actual = Lending::Page.new(outfile)

          aggregate_failures 'output image' do
            %i[width height tile_scale_factors].each do |attr|
              expected_val = page_expected.send(attr)
              actual_val = page_actual.send(attr)
              expect(actual_val).to eq(expected_val), "#{attr}: expected #{expected_val}, got #{actual_val}"
            end
          end
        end
      end
    end

    describe 'class #tileize' do
      it 'tileizes to a specified directory' do
        infile = File.join(samples, 'incoming/00000100.tif')
        expected = File.join(samples, 'final/00000100.tif')

        Dir.mktmpdir do |outdir|
          basename = File.basename(infile)
          outfile = Tileizer.tileize(infile, outdir)
          expect(outfile.to_s).to eq(File.join(outdir, basename))
          expect(outfile.exist?).to eq(true)

          # Note: we can't just compare files because we need to handle minor differences
          # in output across OSes and libvips/libtiff versions, so let's leverage the code
          # we already wrote to detect image tiles for IIIF manifest generation

          page_expected = Lending::Page.new(expected)
          page_actual = Lending::Page.new(outfile)

          aggregate_failures 'output image' do
            %i[width height tile_scale_factors].each do |attr|
              expected_val = page_expected.send(attr)
              actual_val = page_actual.send(attr)
              expect(actual_val).to eq(expected_val), "#{attr}: expected #{expected_val}, got #{actual_val}"
            end
          end
        end
      end

      describe 'tileizing a file to a directory' do
        context 'with skip_existing: true' do
          it 'skips an existing file' do
            expect(Vips::Image).not_to receive(:new_from_file)
            infile = File.join(samples, 'incoming/00000100.tif')
            Dir.mktmpdir do |outdir|
              outfile = File.join(outdir, File.basename(infile))
              FileUtils.touch(outfile)
              Tileizer.tileize(infile, outdir, skip_existing: true)
            end
          end
        end
      end

      describe 'tileizing a file to a file' do
        context 'with skip_existing: true' do
          it 'skips an existing file' do
            expect(Vips::Image).not_to receive(:new_from_file)
            infile = File.join(samples, 'incoming/00000100.tif')
            Dir.mktmpdir do |outdir|
              outfile = File.join(outdir, File.basename(infile))
              FileUtils.touch(outfile)
              Tileizer.tileize(infile, outfile, skip_existing: true)
            end
          end
        end
      end

      describe 'tileizing a directory to a directory' do
        context 'with skip_existing: true' do
          it 'skips an existing file' do
            infile = File.join(samples, 'incoming/00000100.tif')
            Dir.mktmpdir do |outdir|
              outfile = File.join(outdir, File.basename(infile))
              FileUtils.touch(outfile)

              expect(Vips::Image).not_to receive(:new_from_file).with(outfile.to_s, **Tileizer::VIPS_OPTIONS)
              Tileizer.tileize(infile, outfile, skip_existing: true)
            end
          end
        end
      end
    end

    it 'handles failures' do
      allow(Vips::Image).to receive(:new_from_file).and_raise('oops')
      infile = File.join(samples, 'incoming/00000100.tif')
      Dir.mktmpdir do |outdir|
        basename = File.basename(infile)
        outfile = File.join(outdir, basename)
        tileizer = Tileizer.new(infile, outfile)
        expect { tileizer.tileize! }.to raise_error(TileizeFailed)
        expect(File.exist?(outfile)).to eq(false)
      end
    end

    describe :tileize_all do

      it 'tileizes all files in a directory' do
        Dir.mktmpdir do |outdir|
          infiles.each do |f|
            infile = File.join(indir, f)
            outfile = File.join(outdir, f)
            source_img = double(Vips::Image)
            expect(Vips::Image).to receive(:new_from_file).with(infile).and_return(source_img).ordered
            expect(source_img).to receive(:tiffsave).with(outfile.to_s, **Tileizer::VIPS_OPTIONS).ordered
          end

          Tileizer.tileize_all(indir, outdir)
        end
      end

      it 'handles errors in individual files' do
        Dir.mktmpdir do |outdir|
          infiles.each do |f|
            infile = File.join(indir, f)
            outfile = File.join(outdir, f)
            source_img = double(Vips::Image)
            expect(Vips::Image).to receive(:new_from_file).with(infile).and_return(source_img).ordered
            expect(source_img).to receive(:tiffsave).with(outfile.to_s, **Tileizer::VIPS_OPTIONS).and_raise('oops').ordered
          end

          expect { Tileizer.tileize_all(indir, outdir) }.not_to raise_error
        end
      end
    end

    describe :tileize_env do

      before(:each) do
        envvars = [Tileizer::ENV_INFILE, Tileizer::ENV_OUTFILE, Tileizer::SKIP_EXISTING]
        @env_orig = envvars.map { |v| [v, ENV[v]] }.to_h.freeze
        envvars.each { |v| ENV[v] = nil }
      end

      after(:each) do
        @env_orig.each { |v, val| ENV[v] = val }
      end

      it 'tileizes a file' do
        infile = File.join(samples, 'incoming/00000100.tif')
        Dir.mktmpdir do |outdir|
          basename = File.basename(infile)
          outfile = File.join(outdir, basename)
          ENV[Tileizer::ENV_INFILE] = infile
          ENV[Tileizer::ENV_OUTFILE] = outfile

          source_img = double(Vips::Image)
          expect(Vips::Image).to receive(:new_from_file).with(infile).and_return(source_img)
          expect(source_img).to receive(:tiffsave).with(outfile.to_s, **Tileizer::VIPS_OPTIONS)

          Tileizer.tileize_env
        end
      end

      it 'tileizes a directory' do
        Dir.mktmpdir do |outdir|
          ENV[Tileizer::ENV_INFILE] = indir
          ENV[Tileizer::ENV_OUTFILE] = outdir

          infiles.each do |f|
            infile = File.join(indir, f)
            outfile = File.join(outdir, f)
            source_img = double(Vips::Image)
            expect(Vips::Image).to receive(:new_from_file).with(infile).and_return(source_img).ordered
            expect(source_img).to receive(:tiffsave).with(outfile.to_s, **Tileizer::VIPS_OPTIONS).ordered
          end

          Tileizer.tileize_env
        end
      end

      context 'with SKIP_EXISTING' do
        before(:each) do
          ENV[Tileizer::SKIP_EXISTING] = 'skip'
        end

        it 'skips a single file' do
          infile = File.join(samples, 'incoming/00000100.tif')
          Dir.mktmpdir do |outdir|
            basename = File.basename(infile)
            outfile = File.join(outdir, basename)
            ENV[Tileizer::ENV_INFILE] = infile
            ENV[Tileizer::ENV_OUTFILE] = outfile

            FileUtils.touch(outfile)
            expect(Vips::Image).not_to receive(:new_from_file).with(infile)

            Tileizer.tileize_env
          end
        end

        it 'skips existing files in a directory' do
          Dir.mktmpdir do |outdir|
            ENV[Tileizer::ENV_INFILE] = indir
            ENV[Tileizer::ENV_OUTFILE] = outdir

            infiles.each_with_index do |f, i|
              infile = File.join(indir, f)
              outfile = File.join(outdir, f)

              if i.odd?
                source_img = double(Vips::Image)
                expect(Vips::Image).to receive(:new_from_file).with(infile).and_return(source_img).ordered
                expect(source_img).to receive(:tiffsave).with(outfile.to_s, **Tileizer::VIPS_OPTIONS).ordered
              else
                FileUtils.touch(outfile)
                expect(Vips::Image).not_to receive(:new_from_file).with(infile)
              end
            end

            Tileizer.tileize_env
          end
        end
      end
    end
  end
end
