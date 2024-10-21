require 'support/tind_marc_contexts'

module TindMarc
  RSpec.describe SourceCsv do

    describe '#SourceCSV: generate directory asset based on mmsid_tind_info csv file' do
      include_context 'setup', :directory_batch_path, nil, 'with_append'

      let(:source_csv) { described_class.new(batch_info) }

      it 'go through directory batch path' do
        expect(source_csv.assets.length).to eq(1)
      end

    end

    describe '#SourceCsv: generate flat file asset based on mmsid_tind_info csv file' do
      include_context 'setup', :flat_batch_path, 'normal', 'with_append'

      let(:source_csv) { described_class.new(batch_info) }

      it 'generate directory asset from mmsid_tind csv file' do
        expect(source_csv.assets.length).to eq(2)
      end

    end

  end
end
