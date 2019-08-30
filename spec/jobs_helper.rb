require 'rails_helper'

ADMIN_EMAIL = Rails.application.config.altmedia['mail_admin_email']

RSpec.shared_examples 'an email job' do |email_subject_success:, confirm_cc: []|
  include_context 'ssh'
  let(:job) { described_class }

  attr_reader :patron

  before(:each) do
    patron_id = '013191304'
    stub_patron_dump(patron_id)
    @patron = Patron::Record.find(patron_id)

    # not every 'email job' needs SSH, but most do
    allow(ssh).to receive(:exec!).and_return('Finished Successfully')
  end

  it 'sends a success email to the patron' do
    expect { job.perform_now(patron.id) }.to(change { ActionMailer::Base.deliveries.count })
    patron_message = ActionMailer::Base.deliveries.select { |m| m.to && m.to.include?(patron.email) }.last
    expect(patron_message).not_to be_nil
    expect(patron_message.subject).to eq(email_subject_success)
  end

  unless confirm_cc.empty?
    it 'sends a success confirmation email to the CC list' do
      expect { job.perform_now(patron.id) }.to(change { ActionMailer::Base.deliveries.count })
      conf_message = ActionMailer::Base.deliveries.select { |m| m.cc == confirm_cc }.last
      expect(conf_message).not_to be_nil
      expect(conf_message.subject).to eq(email_subject_success)
    end
  end
end

RSpec.shared_examples 'a patron note job' do |note_text:, email_subject_failure:|
  include_context 'ssh'
  let(:job) { described_class }

  attr_reader :patron

  before(:each) do
    patron_id = '013191304'
    stub_patron_dump(patron_id)
    @patron = Patron::Record.find(patron_id)
  end

  it 'adds the expected note' do
    today = Time.now.strftime('%Y%m%d') # TODO: something less fragile
    expected_note = "#{today} #{note_text} [litscript]"
    expected_command = ['/home/altmedia/bin/mkcallnote', expected_note, patron.id].shelljoin
    expect(ssh).to receive(:exec!).with(expected_command).and_return('Finished Successfully')
    job.perform_now(patron.id)
  end

  it 'sends a failure email in the event of an SSH error' do
    allow(ssh).to receive(:exec!).and_raise(Net::SSH::Exception)
    expect { job.perform_now(patron.id) }.to(
      raise_error(Net::SSH::Exception).and(
        (change { ActionMailer::Base.deliveries.count }).by(1)
      )
    )
    last_email = ActionMailer::Base.deliveries.last
    expect(last_email.subject).to eq(email_subject_failure)
    expect(last_email.to).to include(ADMIN_EMAIL)
  end

  it 'sends a failure email in the event of a script error' do
    allow(ssh).to receive(:exec!).and_return('Failed')
    expect { job.perform_now(patron.id) }.to(
      raise_error(StandardError).and(
        (change { ActionMailer::Base.deliveries.count }).by(1)
      )
    )
    last_email = ActionMailer::Base.deliveries.last
    expect(last_email.subject).to eq(email_subject_failure)
    expect(last_email.to).to include(ADMIN_EMAIL)
  end
end
