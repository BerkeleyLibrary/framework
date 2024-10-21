require 'support/tind_marc_contexts'

module TindMarc
  RSpec.describe Source do
    let(:source) { described_class.new(batch_info) }

    describe '#Source: directory batch, normal labels.csv, no tind_mmsid csv file' do
      include_context 'setup', :directory_batch_path, 'normal'

      it 'generate directory asset' do
        expect(source.assets.length).to eq(1)
      end
    end

    describe '#Source: flat file batch, normal labels.csv file, with append tind_mmsid csv file' do
      include_context 'setup', :flat_batch_path, 'normal', 'with_append'

      it 'generate flat file asset' do
        expect(source.assets.length).to eq(2)
      end
    end

  end
end
