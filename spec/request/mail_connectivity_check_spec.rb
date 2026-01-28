require 'rails_helper'
require 'net/smtp'

RSpec.describe MailConnectivityCheck do
  subject(:check) { described_class.new }

  let(:smtp_settings) do
    {
      address: 'smtp.example.com',
      port: 587,
      domain: 'example.com',
      user_name: 'user',
      password: 'password',
      authentication: 'plain',
      tls: true
    }
  end

  before do
    allow(ActionMailer::Base).to receive(:smtp_settings).and_return(smtp_settings)
    allow(Rails.logger).to receive(:warn)
  end

  describe '#check' do
    context 'when SMTP connection succeeds' do
      before do
        allow(Net::SMTP).to receive(:start).and_yield
      end

      it 'marks the check as successful' do
        check.check

        expect(check.success?).to be(true)
        expect(check.message).to eq('Connection for smtp successful')
      end
    end

    context 'when authentication fails' do
      before do
        allow(Net::SMTP).to receive(:start)
          .and_raise(Net::SMTPAuthenticationError.new('auth failed'))
      end

      it 'marks failure and logs authentication error' do
        check.check

        expect(check.success?).to be(false)
        expect(check.message)
          .to eq('SMTP Error: Authentication failed. Check logs for more details')
        expect(Rails.logger)
          .to have_received(:warn).with(/SMTP authentication error/)
      end
    end

    context 'when SMTP protocol errors occur' do
      [
        Net::SMTPServerBusy,
        Net::SMTPSyntaxError,
        Net::SMTPFatalError,
        Net::SMTPUnknownError
      ].each do |error_class|
        it "handles #{error_class.name}" do
          allow(Net::SMTP).to receive(:start)
            .and_raise(error_class.new('smtp error'))

          check.check

          expect(check.success?).to be(false)
          expect(check.message)
            .to eq('SMTP error. Check logs for more details')
          expect(Rails.logger)
            .to have_received(:warn).with(/SMTP Error/)
        end
      end
    end

    context 'when a timeout occurs' do
      [IOError, Net::ReadTimeout].each do |error_class|
        it "handles #{error_class.name}" do
          allow(Net::SMTP).to receive(:start)
            .and_raise(error_class.new('timeout'))

          check.check

          expect(check.success?).to be(false)
          expect(check.message)
            .to eq('SMTP Connection error: Timeout. Check logs for more details')
          expect(Rails.logger)
            .to have_received(:warn).with(/SMTP Timeout/)
        end
      end
    end

    context 'when an unexpected error occurs' do
      before do
        allow(Net::SMTP).to receive(:start)
          .and_raise(StandardError.new('failed'))
      end

      it 'marks failure and logs standard error' do
        check.check

        expect(check.success?).to be(false)
        expect(check.message)
          .to eq('SMTP ERROR: Could not connect. Check logs for more details')
        expect(Rails.logger)
          .to have_received(:warn).with(/SMTP standard error/)
      end
    end
  end
end
