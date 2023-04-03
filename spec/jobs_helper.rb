require 'rails_helper'
require 'concurrent-ruby'
require 'support/async_job_context'

ADMIN_EMAIL = Rails.application.config.altmedia['mail_admin_email']

RSpec.shared_examples 'an email job' do |note_text:, email_subject_success:, confirm_cc: []|
  include_context 'ssh'
  let(:job) { described_class }
  let(:alma_api_key) { 'totally-fake-key' }
  let(:today) { Time.now.strftime('%Y%m%d') }
  let(:expected_note) { "#{today} #{note_text} [litscript]" }

  attr_reader :patron

  before do
    patron_id = '013191305'

    allow(Rails.application.config).to receive(:alma_api_key).and_return(alma_api_key)

    stub_patron_dump(patron_id)
    @patron = Alma::User.find(patron_id)
  end

  it 'sends a success email to the patron' do
    allow(Rails.application.config).to receive(:alma_api_key).and_return(alma_api_key)
    stub_patron_save(patron.id, expected_note)

    expect { job.perform_now(patron.id) }.to(change { ActionMailer::Base.deliveries.count })
    patron_message = ActionMailer::Base.deliveries.select { |m| m.to && m.to.include?(patron.email) }.last
    expect(patron_message).not_to be_nil
    expect(patron_message.subject).to eq(email_subject_success)
  end

  unless confirm_cc.empty?
    it 'sends a success confirmation email to the CC list' do
      allow(Rails.application.config).to receive(:alma_api_key).and_return(alma_api_key)

      stub_patron_save(patron.id, expected_note)

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
  let(:patron_id) { '013191305' }
  let(:alma_api_key) { 'totally-fake-key' }

  attr_reader :patron

  before do
    allow(Rails.application.config).to receive(:alma_api_key).and_return(alma_api_key)

    stub_patron_dump(patron_id)
    @patron = Alma::User.find(patron_id)
  end

  describe 'success' do
    let(:today) { Time.now.strftime('%Y%m%d') }
    let(:expected_note) { "#{today} #{note_text} [litscript]" }

    it 'adds the expected note' do
      stub_patron_save(patron_id, expected_note)
      job.perform_now(patron.id)
    end

    it 'logs before setting the note' do
      expected_msg = "Setting note #{expected_note} for patron #{patron_id}"
      stub_patron_save(patron_id, expected_note)

      allow(Rails.logger).to receive(:debug)
      expect(Rails.logger).to receive(:debug).with(expected_msg)
      job.perform_now(patron.id)
    end

    describe 'async execution' do
      include_context('async execution', job_class: described_class)

      # TODO: More async examples

      it 'logs to the Rails logger even when running in the background' do
        stub_patron_save(patron_id, expected_note)

        expected_msg = "Setting note #{expected_note} for patron #{patron_id}"
        allow(Rails.logger).to receive(:debug)
        expect(Rails.logger).to receive(:debug).with(expected_msg)

        job.perform_later(patron_id)

        await_performed(job)
      end
    end

    it 'logs error on failed email' do
      allow(RequestMailer).to receive(:send).and_raise(StandardError)
      allow(Rails.application.config).to receive(:alma_api_key).and_return(alma_api_key)
      stub_patron_save(patron.id, expected_note)
      expect { job.perform_now(patron.id) }.to raise_error(StandardError)
    end
  end

  describe 'failure' do
    it 'sends a failure email in the event of an error' do
      stub_request(:put, 'https://api-na.hosted.exlibrisgroup.com/almaws/v1/users/013191305')
        .to_raise(StandardError)

      expect { job.perform_now(patron.id) }.to(
        raise_error(StandardError).and(
          (change { ActionMailer::Base.deliveries.count }).by(1)
        )
      )
      last_email = ActionMailer::Base.deliveries.last
      expect(last_email.subject).to eq(email_subject_failure)
      expect(last_email.to).to include(ADMIN_EMAIL)
    end

    # it 'logs an error in the event of an email send failure' do
    #   allow(RequestMailer).to receive(:send).and_raise(StandardError)

    #   #allow_any_instance_of(ActionMailer::MessageDelivery).to receive(:deliver_now).and_raise(StandardError)

    #   # expect(Rails.logger).to receive(:error) do |msg, &block|
    #   #   msg ||= block.call
    #   #   expect(msg.to_s).to include(err_class.to_s)
    #   # end.at_least(:once)

    #   expect { job.perform_now(patron.id) }.to raise_error(StandardError)
    # end

    it 'logs an error in the event of a patron lookup failure' do
      bad_patron_id = '2127365000'

      err_class = Error::PatronApiError
      allow(Alma::User).to receive(:find).with(bad_patron_id).and_raise(err_class)

      expect(Rails.logger).to receive(:error) do |msg, &block|
        msg ||= block.call
        expect(msg.to_s).to include(err_class.to_s)
      end.at_least(:once) # TODO: avoid double-logging

      # Can't just use raise_error here; see https://github.com/rspec/rspec-expectations/issues/1293
      ex = begin
        job.perform_now(bad_patron_id)
      rescue StandardError => e
        e.tap { raise if e.class.name.start_with?('RSpec') }
      end
      expect(ex).to be_a(Error::PatronApiError)
    end

    it 'logs an error in the event of a script error' do
      err_msg = 'something bad'

      stub_request(:put, 'https://api-na.hosted.exlibrisgroup.com/almaws/v1/users/013191305')
        .to_raise(err_msg)

      expect(Rails.logger).to receive(:error) do |msg|
        expect(msg).to include(msg: err_msg, backtrace: an_instance_of(Array))
      end.ordered

      expect(Rails.logger).to receive(:error) do |msg, &block|
        expect(msg).to be_nil
        msg_actual = block.call
        expect(msg_actual).to include(job.name)
        expect(msg_actual).to include(err_msg)
      end.ordered

      expect { job.perform_now(patron.id) }.to raise_error(StandardError)
    end
  end
end
