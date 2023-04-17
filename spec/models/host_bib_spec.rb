require 'rails_helper'
require 'marc'

RSpec.describe Bibliographic::HostBib, type: :model do
  let(:record_id) { double('record_id') }
  let(:mms_id) { '991083840969706532' }
  let(:host_bib_task) { Bibliographic::HostBibTask.create(filename: 'fake.txt') }
  let(:marc_stub) { instance_double(MARC::Record) }

  after do
    Bibliographic::HostBibTask.find(host_bib_task.id).destroy if host_bib_task.persisted?
  end

  def marc_stub
    record = MARC::Record.new
    record.leader = '00096nam a2200049 i 4500'
    control_field = MARC::ControlField.new('001', '123456789')
    record.append(control_field)
    data_field1 = MARC::DataField.new('774', '0', '1', ['t', 'Seconde partie du discours aux Welches '], %w[w 991083840969706532], %w[9 Exl])
    data_field2 = MARC::DataField.new('774', '0', '1', ['t', 'Où va donc largent.'], %w[w 991083840969706532], %w[9 Exl])
    record.append(data_field1)
    record.append(data_field2)
    record
  end

  context 'AlmaServices::Marc has' do
    it 'alma marc' do
      class_double(BerkeleyLibrary::Alma::RecordId, parse: record_id).as_stubbed_const
      expect(record_id).to receive(:get_marc_record).and_return('marc_stub')
      expect(AlmaServices::Marc.record(mms_id)).to eq('marc_stub')
    end
  end

  RSpec.shared_examples 'host_bib has alma marc' do |marc_status|
    it "marc_status: '#{marc_status}'" do
      host_bib = host_bib_task.host_bibs.create(mms_id:, marc_status:)
      allow(AlmaServices::Marc).to receive(:record).with(mms_id).and_return(marc_stub)
      Bibliographic::HostBib.create_linked_bibs(host_bib)
      host_bib_updated = Bibliographic::HostBib.find(host_bib.id)
      expect(host_bib_updated.marc_status).to eq('retrieved')
    end
  end

  context 'host_bib not nil' do
    it_behaves_like 'host_bib has alma marc', 'pending'
    it_behaves_like 'host_bib has alma marc', 'retrieving'
  end

  context 'host_bib nil' do
    it 'marc_record nil' do
      host_bib = host_bib_task.host_bibs.create(mms_id:)
      allow(AlmaServices::Marc).to receive(:record).with(mms_id).and_return(nil)
      Bibliographic::HostBib.create_linked_bibs(host_bib)
      expect(Bibliographic::HostBib.find(host_bib.id).marc_status).to eq('failed')
    end
  end

end
