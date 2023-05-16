require 'rails_helper'

describe EfinesInvoice do
  let(:alma_api_key) { 'fake-api-key' }
  let(:request_headers) { { 'Accept' => 'application/json', 'Authorization' => "apikey #{alma_api_key}" } }

  before do
    alma_id = '10335026'

    stub_request(:get, "https://api-na.hosted.exlibrisgroup.com/almaws/v1/users/#{alma_id}?expand=fees&view=full")
      .with(headers: request_headers)
      .to_return(status: 200, body: File.new('spec/data/fines/efine-lookup-data.json'))

    stub_request(:get, "https://api-na.hosted.exlibrisgroup.com/almaws/v1/users/#{alma_id}/fees")
      .with(headers: request_headers)
      .to_return(status: 200, body: File.new('spec/data/fines/efine-lookup-fees.json'))

    @invoice = EfinesInvoice.new(alma_id)
  end

  it 'encodes the user info into a jwt' do
    decoded_token = EfinesInvoice.decode(@invoice.jwt)
    expect(decoded_token[0] { userName }).to have_key('userName')
    expect(decoded_token[0] { userName }).to have_value('10335026')
  end

  it 'submits the request mailer' do
    @invoice.submit!
  end
end
