require 'rails_helper'
require 'marc'

module TindMarc
  RSpec.describe AlmaTind do

    let(:alma_tind) { TindMarc::AlmaTind.new }

    def marc_stub
      record = MARC::Record.new
      record.leader = '00096nam a2200049 i 4500'
      control_field = MARC::ControlField.new('001', '123456789')
      record.append(control_field)
      data_field = MARC::DataField.new('336', '', '', %w[a image])
      record.append(data_field)
      data_field = MARC::DataField.new('852', '', '', ['a', 'The Berkeley Library'])
      record.append(data_field)
      data_field = MARC::DataField.new('980', '', '', ['a', 'facet field'])
      record.append(data_field)
      data_field = MARC::DataField.new('982', '', '', ['a', 'short collection name'])
      record.append(data_field)
      data_field = MARC::DataField.new('982', '', '', ['b', 'long collection name'])
      record.append(data_field)
      data_field = MARC::DataField.new('991', '', '', ['p', 'project name'])
      record.append(data_field)
      record
    end

    # it 'was instantiated and can call methods' do
    # expect(marc_batch).to respond_to(:prepare)
    # expect(marc_batch).to respond_to(:produce_marc)
    # expect(marc_batch).to respond_to(:send_email)
    # end

    # it 'gets the alma_id from a string' do
    # expect(marc_batch.alma_id('9918283094_C19193293')).to eq('9918283094')
    # end

    it 'does NOT raise error' do
      expect { alma_tind.setup_collection('tag_336', 'tag_852', 'tag_980', 'tag_982_a', 'tag_982_b', 'tag_991') }.not_to raise_error
      expect { alma_tind.additional_tind_fields('key', %w[file1 file2], 'url_base', 'field_980a', 'rights') }.not_to raise_error
      expect { alma_tind.add_fft(['file1, file2'], 'url_base', marc_stub) }.not_to raise_error
    end

    # it 'does NOT rails error' do
    # expect { marc_batch.print_out }.not_to raise_error
    # end
    #
    # it 'does NOT raise error' do
    # expect { marc_batch.produce_marc(marc_batch.assets) }.not_to raise_error
    # end
    #
    # it 'does NOT raise error' do
    # expect { marc_batch.send(:update_field, marc_stub) }.not_to raise_error
    # end
    #
    # it 'does NOT have a marc leader' do
    # expect { marc_batch.send(:remove_leader_and_namespace, marc_stub) }.not_to raise_error
    # end
    #
    # it 'logs an error' do
    # expect(Rails.logger).to receive(:error)
    # end
    #
    # it 'calls AssetFiles and receives a hash' do
    # expect(marc_batch.assets.file_hash).to have_key('991040470099706532_C082377373')
    # end

  end
end
