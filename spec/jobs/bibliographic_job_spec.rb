require 'jobs_helper'

RSpec.describe BibliographicJob, type: :job do
  let(:email) { 'test@test.com' }
  let(:host_bib_task) { Bibliographic::HostBibTask.create(filename: 'fake.txt', email:) }
  let(:mms_id1) { '991082670399706532' }

  after do
    Bibliographic::HostBibTask.find(host_bib_task.id).destroy if host_bib_task.persisted?
  end

  describe '#perform' do
    it 'The job is queued' do
      BibliographicJob.perform_later(host_bib_task)
      expect(BibliographicJob).to have_been_enqueued.with(host_bib_task)
    end

    it 'The job is excuted' do
      host_bib = host_bib_task.host_bibs.create(mms_id: mms_id1, marc_status: 'pending')
      allow(AlmaServices::Marc).to receive(:record).and_return(nil)
      BibliographicJob.perform_now(host_bib_task)
      expect(host_bib_task.host_bibs.find(host_bib.id).marc_status).to eq('failed')
    end
  end

  describe '#Error perform' do
    it 'raises an error' do
      host_bib = host_bib_task.host_bibs.create(mms_id: mms_id1, marc_status: 'pending')
      allow(Bibliographic::HostBib).to receive(:create_linked_bibs).with(host_bib).and_raise(RuntimeError)

      expect { BibliographicJob.perform_now(host_bib_task) }.to raise_error(RuntimeError)
      expect(host_bib_task.status).to eq('failed')

    end

  end

end
