require 'rails_helper'

describe PatronNoteJobBase, type: :job do
  let(:patron_id) { '12345' }
  let(:mailer_prefix) { 'test_prefix' }
  let(:note_txt) { 'Test note text' }

  let(:job) do
    described_class.new(mailer_prefix:, note_txt:)
  end

  let(:patron) do
    instance_double(
      Alma::User,
      email: 'mrperson@test.com',
      id: patron_id,
      name: 'Bud Powell'
    )
  end

  let(:mail_double) do
    instance_double(ActionMailer::MessageDelivery, deliver_now: true)
  end

  before do
    allow(Alma::User).to receive(:find_if_active).with(patron_id).and_return(patron)

    allow(patron).to receive(:delete_note)
    allow(patron).to receive(:add_note)
    allow(patron).to receive(:save)
  end

  describe '#perform' do
    it 'finds patron and adds note' do
      expect(patron).to receive(:delete_note).with(note_txt)
      expect(patron).to receive(:add_note).with(job.note)
      expect(patron).to receive(:save)

      allow(RequestMailer)
        .to receive(:send)
        .and_return(mail_double)

      job.perform(patron_id)
    end

    it 'sends confirmation email' do
      expect(RequestMailer)
        .to receive(:send)
        .with("#{mailer_prefix}_confirmation_email", patron.email)
        .and_return(mail_double)

      job.perform(patron_id)
    end

    it 'formats note with date and tag' do
      allow(RequestMailer).to receive(:send).and_return(mail_double)

      travel_to Date.new(2025, 1, 1) do
        job.perform(patron_id)
        expect(job.note).to eq("20250101 #{note_txt} [litscript]")
      end
    end
  end

  describe 'when patron lookup fails' do
    it 'logs and raises error' do
      allow(Alma::User).to receive(:find_if_active).and_raise(StandardError.new('fail'))

      expect(job).to receive(:log_error).at_least(:once)

      expect { job.perform(patron_id) }.to raise_error(StandardError)
    end
  end

  describe 'when add_note fails' do
    before do
      allow(RequestMailer).to receive(:send).and_return(mail_double)
      allow(patron).to receive(:add_note).and_raise(StandardError.new('boom'))
    end

    it 'sends failure email' do
      expect(RequestMailer)
        .to receive(:send)
        .with(
          "#{mailer_prefix}_failure_email",
          patron.id,
          patron.name,
          job.note
        )
        .and_return(mail_double)

      expect { job.perform(patron_id) }.to raise_error(StandardError)
    end

    it 'logs error' do
      expect(job).to receive(:log_error).at_least(:once)

      expect { job.perform(patron_id) }.to raise_error(StandardError)
    end
  end

  describe 'when confirmation email fails' do
    it 'logs and raises error' do
      allow(RequestMailer)
        .to receive(:send)
        .and_raise(StandardError.new('mail fail'))

      expect(job).to receive(:log_error).at_least(:once)

      expect { job.perform(patron_id) }.to raise_error(StandardError)
    end
  end

  describe 'when failure email itself fails' do
    before do
      allow(patron).to receive(:add_note).and_raise(StandardError.new('note fail'))
      allow(RequestMailer).to receive(:send).and_raise(StandardError.new('mail fail'))
    end

    it 'logs and raises error' do
      expect(job).to receive(:log_error).at_least(:once)

      expect { job.perform(patron_id) }.to raise_error(StandardError)
    end
  end
end
