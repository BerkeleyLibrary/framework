require 'rails_helper'
require 'lending/tileizer'

module Lending
  describe Tileizer do
    let(:samples) { '/Users/david/Work/altmedia/spec/data/lending/samples' }

    it 'tileizes' do
      infile = File.join(samples, 'b135297126_C068087930-00000100-sm.tif')
      expected = File.join(samples, 'b135297126_C068087930-00000100-sm-tiled.tif')

      Dir.mktmpdir do |outdir|
        basename = File.basename(infile)
        outfile = File.join(outdir, basename)
        tileizer = Tileizer.new(infile, outfile)
        tileizer.tileize!
        expect(tileizer).to be_tileized
        expect(FileUtils.identical?(outfile, expected)).to eq(true)
      end
    end

    describe :tileize_all do
      let(:indir) { 'spec/data/lending/incoming/b100523250_C044235662' }
      let(:infiles) { Dir.entries(indir).select { |f| f.end_with?('.tif') }.sort }

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
    end
  end
end
