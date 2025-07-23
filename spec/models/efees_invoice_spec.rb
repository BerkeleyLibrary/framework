require 'rails_helper'

describe EfeesInvoice do
  let(:alma_api_key) { 'fake-api-key' }
  let(:request_headers) { { 'Accept' => 'application/json', 'Authorization' => "apikey #{alma_api_key}" } }

  before do
    alma_id = '10335026'

    allow(Rails.application.config).to receive(:alma_api_key).and_return(alma_api_key)

    stub_request(:get, "https://api-na.hosted.exlibrisgroup.com/almaws/v1/users/#{alma_id}?expand=fees&view=full")
      .with(headers: request_headers)
      .to_return(status: 200, body: File.new('spec/data/fees/efee-lookup-data.json'))

    stub_request(:get, "https://api-na.hosted.exlibrisgroup.com/almaws/v1/users/#{alma_id}/fees")
      .with(headers: request_headers)
      .to_return(status: 200, body: File.new('spec/data/fees/efee-lookup-fees.json'))

    @invoice = EfeesInvoice.new(alma_id)
  end

  it 'encodes the user info into a jwt' do
    decoded_token = EfeesInvoice.decode(@invoice.jwt)
    expect(decoded_token[0] { userName }).to have_key('userName')
    expect(decoded_token[0] { userName }).to have_value('10335026')
  end

  it 'submits the request mailer' do # rubocop:disable RSpec/NoExpectationExample
    @invoice.submit!
  end
end
