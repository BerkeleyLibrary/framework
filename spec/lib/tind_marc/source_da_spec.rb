require 'support/tind_marc_contexts'

module TindMarc
  RSpec.describe SourceDa do
    let(:source_da) { described_class.new(batch_info) }

    describe '#SourceDa: flat-file-type not effect assets from directory' do
      include_context 'setup', :directory_batch_path, 'normal'

      it 'generate directory asset from DA directories' do
        expect(source_da.assets.length).to eq(1)
      end
    end

    describe '#SourceDa: flat-file-type effects assets retrieval from flat files' do
      describe 'with flat-file-type (MMSID)' do
        include_context 'setup', :flat_batch_path, nil, 'no_append'

        it 'generate flat file asset, from DA directories, based on no_append mmsid_tind_info csv file and MMSID' do
          expect(source_da.assets.length).to eq(2)
        end
      end

      describe 'with flat-file-type(MMSID + Barcode)' do
        include_context 'setup', :flat_batch_path, nil, 'no_append', '1'

        it 'generate flat file asset, from DA directories, based on mmsid_tind_info csv file and MMSID + Barcode' do
          expect(source_da.assets.length).to eq(3)
        end
      end

    end

  end
end
