require 'support/tind_marc_contexts'
require 'marc'

module TindMarc
  RSpec.describe Asset do
    include_context 'setup', :directory_batch_path, 'normal', 'with_append'
    let(:asset) { described_class.new(batch_info, '991000401929706532', filenames) }

    describe '#Asset: directory batch, normal label file, with append tind_mmsid file, the directory has digital files' do
      let(:filenames) { ['name1.jpg', 'name2.jpg'] }

      it 'create 001 field' do
        expect(asset.tind_control_f_001).to be_a(MARC::ControlField)
      end
    end

    describe '#Asset: directory batch, normal label file, with append tind_mmsid file, the directory has no digital files' do
      let(:filenames) { [] }

      it 'An error message in asset' do
        expect(asset.errors.length).to eq(1)
      end
    end

  end
end
