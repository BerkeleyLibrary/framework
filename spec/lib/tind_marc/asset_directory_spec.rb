require 'support/tind_marc_contexts'

module TindMarc
  RSpec.describe AssetDirectory do
    let(:asset_dir) { described_class.new(batch_info, '991000401929706532') }

    describe '#AssetDirectory: directory batch, normal labels.csv file' do
      include_context 'setup', :directory_batch_path, 'normal', nil

      it 'generate ffts with labels' do
        expect(asset_dir.ffts.length).to eq(6)
      end
    end

    describe '#AssetDirectory: directory batch, less labels.csv file' do
      include_context 'setup', :directory_batch_path, 'less', nil

      it 'some directory asset files not found in labels.csv' do
        expect { asset_dir.ffts }.to change(asset_dir.warnings, :length).by(3)
      end

    end
  end
end
