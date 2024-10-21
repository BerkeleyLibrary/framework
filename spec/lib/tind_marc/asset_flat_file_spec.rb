require 'support/tind_marc_contexts'

module TindMarc
  RSpec.describe AssetFlatFile do
    include_context 'setup', :flat_batch_path
    let(:mmsid_flat_file_type) { '991000401929706532' }
    let(:mmsid_and_barcode_flat_file_type) { '991000401929706532_C052981918' }

    describe '#AssetFlatFile: return different ffts and f_035$a with different flat-file-types' do

      describe 'flatfile batch, no lable file, no tind_mmsid file, flat_file_type(MMSID)' do
        let(:asset_flat_file) { described_class.new(batch_info, mmsid_flat_file_type) }

        it 'generate two ffts' do
          expect(asset_flat_file.ffts.length).to eq(2)
        end

        it 'generate 035' do
          expect(asset_flat_file.f_035['a']).to eq('(fake_prefix)991000401929706532')
        end
      end

      describe 'flatfile batch, no lable file, no tind_mmsid file, flat_file_type (MMSID + Barcode)' do
        let(:asset_flat_file) { described_class.new(batch_info, mmsid_and_barcode_flat_file_type) }

        it 'generate one fft' do
          expect(asset_flat_file.ffts.length).to eq(1)
        end

        it 'generate 035' do
          expect(asset_flat_file.f_035['a']).to eq('(fake_prefix)991000401929706532_C052981918')
        end
      end
    end
  end
end
