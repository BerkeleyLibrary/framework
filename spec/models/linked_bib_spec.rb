require 'rails_helper'
require 'marc'

RSpec.describe Bibliographic::LinkedBib, type: :model do
  let(:mms_id) { '991083840969706532' }
  let(:host_bib_task) { Bibliographic::HostBibTask.create(filename: 'fake.txt') }
  let(:host_bib) { host_bib_task.host_bibs.create(mms_id:) }

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

  it 'marc_record: nil' do
    allow(AlmaServices::Marc).to receive(:record).with(mms_id).and_return(nil)
    Bibliographic::LinkedBib.from_mmsid(host_bib, mms_id)
    updated_linked_bib = Bibliographic::LinkedBib.find(host_bib.linked_bibs[0].id)
    expect(updated_linked_bib.marc_status).to eq('failed')
  end

  it 'marc_record:retrieved' do
    allow(AlmaServices::Marc).to receive(:record).with(mms_id).and_return(marc_stub)
    Bibliographic::LinkedBib.from_mmsid(host_bib, mms_id)
    updated_linked_bib = Bibliographic::LinkedBib.find(host_bib.linked_bibs[0].id)
    expect(updated_linked_bib.marc_status).to eq('retrieved')
  end

end
