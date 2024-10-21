require 'fileutils'
require 'support/tind_marc_contexts'

module TindMarc
  RSpec.describe BatchInfo do
    let(:batch_info) { described_class.new(args) }

    describe '#BatchInfo: error handling' do
      include_context 'setup', :directory_batch_path, 'normal'
      before do
        allow(File).to receive(:open).and_raise(StandardError.new('!'))
      end

      it 'raise an error when file does not exist' do
        error = 'Run into a problem when creating hash from lable.csv file at '
        at = '/opt/app/spec/data/tind_marc/data/da/directory_collection/ucb/incoming/labels.csv. !'
        expect(Util).to receive(:raise_error).with("#{error}#{at}")
        batch_info.create_label_hash
      end
    end

  end

end
