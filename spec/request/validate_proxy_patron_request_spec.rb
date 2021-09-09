require 'rails_helper'

describe 'Valid Alma Proxy Patron', type: :request do
  let(:alma_api_key) { 'Config.alma_api_key' }

  # To fake it, we need to override it in the config:
  before(:each) do
    allow(Rails.application.config).to receive(:alma_api_key).and_return(alma_api_key)
  end

  it 'alerts user of invalid parameters' do
    expect { post('/validate_proxy_patron', {}) }.to raise_error ActionController::ParameterMissing
  end

  it 'alerts user if they failed to authenticate' do
    stub_request(:post, "https://api-na.hosted.exlibrisgroup.com/almaws/v1/users/10000000?apikey=#{alma_api_key}&op=auth&password=fakepass&view=full")
      .with(headers: { 'Accept' => 'application/json' })
      .to_return(status: 403, body: '', headers: {})

    post '/validate_proxy_patron', params: { alma_id: '10000000', alma_password: 'fakepass' }
    expect(response.status).to eq(403)
    expect(response.body).to include('Fail')
  end

  it 'authorizes a user' do
    # Stub the login:
    stub_request(:post, "https://api-na.hosted.exlibrisgroup.com/almaws/v1/users/10000001?apikey=#{alma_api_key}&op=auth&password=fakepass&view=full")
      .with(headers: { 'Accept' => 'application/json' })
      .to_return(status: 204, body: '', headers: {})

    # Stub the api response:
    stub_request(:get, "https://api-na.hosted.exlibrisgroup.com/almaws/v1/users/10000001?apikey=#{alma_api_key}&expand=fees&view=full")
      .with(headers: { 'Accept' => 'application/json' })
      .to_return(status: 200, body: File.new('spec/data/alma_patrons/10000001.json'))

    post '/validate_proxy_patron', params: { alma_id: '10000001', alma_password: 'fakepass' }
    expect(response.status).to eq(200)
    expect(response.body).to include('Success')
  end

  it 'does not authorize a patron with more than 50 dollars in fees' do
    stub_request(:post, "https://api-na.hosted.exlibrisgroup.com/almaws/v1/users/10000002?apikey=#{alma_api_key}&op=auth&password=fakepass&view=full")
      .with(headers: { 'Accept' => 'application/json' })
      .to_return(status: 204, body: '', headers: {})

    stub_request(:get, "https://api-na.hosted.exlibrisgroup.com/almaws/v1/users/10000002?apikey=#{alma_api_key}&expand=fees&view=full")
      .with(headers: { 'Accept' => 'application/json' })
      .to_return(status: 200, body: File.new('spec/data/alma_patrons/10000002.json'))

    post '/validate_proxy_patron', params: { alma_id: '10000002', alma_password: 'fakepass' }
    expect(response.status).to eq(403)
    expect(response.body).to include('Fail')
  end

end
