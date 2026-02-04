require 'rails_helper'
require 'marc'

RSpec.describe Bibliographic::LinkedBib, type: :model do
  let(:mms_id) { '991083840969706532' }
  let(:host_bib_task) { Bibliographic::HostBibTask.create(filename: 'fake.txt', email: 'test@test.example') }
  let(:host_bib) { host_bib_task.host_bibs.create(mms_id:) }
  let(:subfields_from_774) { { 'w' => '991083840969706532', 't' => 'Seconde partie du discours aux Welches ' } }

  after do
    Bibliographic::HostBibTask.find(host_bib_task.id).destroy if host_bib_task.persisted?
  end

  def marc_stub
    record = MARC::Record.new
    record.leader = '00096nam a2200049 i 4500'
    control_field = MARC::ControlField.new('001', '123456789')
    record.append(control_field)
    data_field = MARC::DataField.new('035', '', '', ['a', '(OCoLC)779630683'])
    record.append(data_field)
    record
  end

  describe 'marc_status' do
    it 'marc_record: nil' do
      allow(AlmaServices::Marc).to receive(:record).with(mms_id).and_return(nil)
      Bibliographic::LinkedBib.from_774(host_bib, subfields_from_774)
      updated_linked_bib = Bibliographic::LinkedBib.find(host_bib.linked_bibs[0].id)
      expect(updated_linked_bib.marc_status).to eq('failed')
    end

    it 'marc_record:retrieved' do
      allow(AlmaServices::Marc).to receive(:record).with(mms_id).and_return(marc_stub)
      Bibliographic::LinkedBib.from_774(host_bib, subfields_from_774)
      updated_linked_bib = Bibliographic::LinkedBib.find(host_bib.linked_bibs[0].id)
      expect(updated_linked_bib.marc_status).to eq('retrieved')
    end
  end

  describe 'create linked_bib' do
    it 'create linked_bib' do
      allow(AlmaServices::Marc).to receive(:record).with(mms_id).and_return(marc_stub)
      linked_bib = Bibliographic::LinkedBib.from_774(host_bib, subfields_from_774)
      expect(linked_bib.mms_id).to eq('991083840969706532')
      expect(linked_bib.marc_status).to eq('retrieved')
      expect(linked_bib.field_035).to eq('(OCoLC)779630683')
    end

    it 'create linked_bib with nil field_035' do
      allow(AlmaServices::Marc).to receive(:record).with(mms_id).and_return(nil)
      linked_bib = Bibliographic::LinkedBib.from_774(host_bib, subfields_from_774)
      expect(linked_bib.field_035).to be_nil
    end
  end
end
