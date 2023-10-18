require 'rails_helper'
require 'marc'

module TindMarc
  RSpec.describe BatchCreator do

    params = { directory: 'librettos/incoming', resource_type: 'Text',
               library: 'The Bancroft Library', f_540_a: 'some rights statement',
               f_980_a: 'map field 980a', f_982_a: 'short collection name',
               f_982_b: 'long collection name', f_982_p: 'larger project',
               restriction: 'Restricted2Bancroft', email: 'some_email@nowhere.com' }

    let(:marc_batch) { TindMarc::BatchCreator.new(params) }

    def marc_stub
      record = MARC::Record.new
      record.leader = '00096nam a2200049 i 4500'
      control_field = MARC::ControlField.new('001', '123456789')
      record.append(control_field)
      data_field = MARC::DataField.new('035', '', '', ['a', '(OCoLC)779630683'])
      record.append(data_field)
      record
    end

    it 'was instantiated and can call methods' do
      expect(marc_batch).to respond_to(:prepare)
      expect(marc_batch).to respond_to(:produce_marc)
      expect(marc_batch).to respond_to(:send_email)
    end

    it 'gets the alma_id from a string' do
      expect(marc_batch.alma_id('9918283094_C19193293')).to eq('9918283094')
    end

    it 'does NOT raise error' do
      expect { marc_batch.prepare }.not_to raise_error
      expect { marc_batch.print_out }.not_to raise_error
      # expect { marc_batch.produce_marc(marc_batch.assets) }.not_to raise_error
      expect { marc_batch.send(:update_field, marc_stub) }.not_to raise_error
    end

    it 'does NOT have a marc leader' do
      expect { marc_batch.send(:remove_leader_and_namespace, marc_stub) }.not_to raise_error
    end

    # it 'logs an error' do
    # allow(marc_batch).to receive(:assets).and_raise(:StandardError)
    # allow(marc_batch.assets).to receive(AssetFile.new('some_dir')).and_raise(StandardError)
    # allow(marc_batch.assets).to receive(AssetFile.new('some_dir'))

    # expect { marc_batch.assets}.to raise_error(StandardError)
    # expect do
    # marc_batch.assets
    # end.to raise_error(StandardError)
    # end

    it 'calls AssetFiles and receives a hash' do
      expect(marc_batch.assets.file_inventory).to have_key('991039504079706532_C082367566')
    end

  end
end
