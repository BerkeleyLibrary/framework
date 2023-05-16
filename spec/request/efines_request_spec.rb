require 'forms_helper'

describe 'Efines', type: :request do
  def base_url_for(user_id = nil)
    "https://api-na.hosted.exlibrisgroup.com/almaws/v1/users/#{user_id}"
  end

  let(:alma_api_key) { 'totally-fake-key' }
  let(:request_headers) { { 'Accept' => 'application/json', 'Authorization' => "apikey #{alma_api_key}" } }

  before do
    login_as_patron('013191304')

    allow(Rails.application.config).to receive(:alma_api_key).and_return(alma_api_key)
  end

  it 'lookup form renders' do
    get efines_path
    expect(response.status).to eq(200)
    expect(response.body).to include('Non UC Berkeley Patron Fee Payments')
  end

  it 'alerts user if patron is not found' do
    user_id = 'fake-user-id'

    stub_request(:get, "#{base_url_for user_id}?expand=fees&view=full")
      .with(headers: request_headers)
      .to_raise(ActiveRecord::RecordNotFound)

    get "/efines/lookup?alma_id=#{user_id}"
    follow_redirect!

    expect(response.body).to include("Error: No patron found with Alma ID: #{user_id}")
  end

  it 'lists user info and fees' do
    user_id = '10335026'

    stub_request(:get, "#{base_url_for user_id}?expand=fees&view=full")
      .with(headers: request_headers)
      .to_return(status: 200, body: File.new('spec/data/fines/efine-lookup-data.json'))

    stub_request(:get, "#{base_url_for user_id}/fees")
      .with(headers: request_headers)
      .to_return(status: 200, body: File.new('spec/data/fines/efine-lookup-fees.json'))

    get "/efines/lookup?alma_id=#{user_id}"

    expect(response.body).to include('Steven M Sullivan')
  end

  it 'link sent via email opens the patron select fees to pay page' do
    user_id = '10335026'

    stub_request(:get, "#{base_url_for user_id}?expand=fees&view=full")
      .with(headers: request_headers)
      .to_return(status: 200, body: File.new('spec/data/fines/efine-lookup-data.json'))

    stub_request(:get, "#{base_url_for user_id}/fees")
      .with(headers: request_headers)
      .to_return(status: 200, body: File.new('spec/data/fines/efine-lookup-fees.json'))

    # Create a new invoice
    invoice = EfinesInvoice.new(user_id)

    get "/efine?type=efine&jwt=#{invoice.jwt}"
    expect(response.body).to include('fine_payment_17178894740006532')
    expect(response.body).to include('fine_payment_17178894770006532')
  end

  it 'link redirects to error page if request has a non-existant alma id' do
    stub_request(:get, "#{base_url_for}fees")
      .with(headers: request_headers)
      .to_return(status: 404, body: '')

    get '/efine?&type-efine&jwt=totallyfakejwt'
    follow_redirect!
    expect(response.status).to eq(200)
    expect(response.body).to include('Error')
  end

end
