require 'rails_helper'

describe EfeesInvoice do
  include ActiveJob::TestHelper

  let(:alma_api_key) { 'fake-api-key' }
  let(:alma_id) { '10335026' }
  let(:request_headers) do
    {
      'Accept' => 'application/json',
      'Authorization' => "apikey #{alma_api_key}"
    }
  end

  context 'JWT generation' do
    before do
      allow(Rails.application.config)
        .to receive(:alma_api_key)
        .and_return(alma_api_key)

      stub_request(
        :get,
        "https://api-na.hosted.exlibrisgroup.com/almaws/v1/users/#{alma_id}?expand=fees&view=full"
      )
        .with(headers: request_headers)
        .to_return(
          status: 200,
          body: File.new('spec/data/fees/efee-lookup-data.json')
        )

      stub_request(
        :get,
        "https://api-na.hosted.exlibrisgroup.com/almaws/v1/users/#{alma_id}/fees"
      )
        .with(headers: request_headers)
        .to_return(
          status: 200,
          body: File.new('spec/data/fees/efee-lookup-fees.json')
        )
    end

    it 'encodes the user info into a jwt' do
      invoice = EfeesInvoice.new(alma_id)
      decoded_token = EfeesInvoice.decode(invoice.jwt)

      expect(decoded_token[0]).to have_key('userName')
      expect(decoded_token[0]['userName']).to eq(alma_id)
    end
  end

  describe '#submit!' do
    let(:alma_id) { '123456' }

    let(:user_double) do
      double(
        id: alma_id,
        email: 'test@example.com',
        name: 'Test User',
        fees: 100.0
      )
    end

    before do
      allow(Alma::User)
        .to receive(:find_if_exists)
        .with(alma_id)
        .and_return(user_double)
    end

    it 'enqueues the efee invoice email' do
      invoice = EfeesInvoice.new(alma_id)

      expect { invoice.submit! }.to have_enqueued_job(ActionMailer::MailDeliveryJob)
        .with(
          'RequestMailer',
          'efee_invoice_email',
          'deliver_now',
          { args: [alma_id] }
        )
    end
  end
end
