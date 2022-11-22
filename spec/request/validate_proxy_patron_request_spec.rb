require 'rails_helper'

describe 'Valid Alma Proxy Patron', type: :request do
  def base_url_for(user_id)
    "https://api-na.hosted.exlibrisgroup.com/almaws/v1/users/#{user_id}"
  end

  let(:alma_api_key) { 'not-the-api-key' }
  let(:valid_user_id) { '10000001' }
  let(:alma_password) { 'fakepass' }
  let(:request_headers) { { 'Accept' => 'application/json', 'Authorization' => "apikey #{alma_api_key}" } }

  # To fake it, we need to override it in the config:
  before do
    allow(Rails.application.config).to receive(:alma_api_key).and_return(alma_api_key)
  end

  it 'alerts user of invalid parameters' do
    expect { post('/validate_proxy_patron') }.to raise_error ActionController::ParameterMissing
  end

  it 'alerts user if they failed to authenticate' do
    invalid_user_id = '10000003'
    url = base_url_for(invalid_user_id)

    stub_request(:post, url)
      .with(
        headers: request_headers,
        query: { op: 'auth', password: alma_password, view: 'full' }
      )
      .to_return(status: 403, body: '', headers: {})

    post '/validate_proxy_patron', params: { alma_id: invalid_user_id, alma_password: }
    expect(response.status).to eq(403)
    expect(response.body).to include('Fail')
  end

  it 'authorizes a user' do
    url = base_url_for(valid_user_id)

    stub_request(:post, url)
      .with(
        headers: request_headers,
        query: { op: 'auth', password: alma_password, view: 'full' }
      )
      .to_return(status: 204, body: '', headers: {})

    stub_request(:get, url)
      .with(
        headers: request_headers,
        query: { expand: 'fees', view: 'full' }
      )
      .to_return(status: 200, body: File.new("spec/data/alma_patrons/#{valid_user_id}.json"))

    post '/validate_proxy_patron', params: { alma_id: valid_user_id, alma_password: }
    expect(response.status).to eq(200)
    expect(response.body).to include('Success')
  end

  it 'does not authorize a patron with more than 50 dollars in fees' do
    blocked_user_id = '10000002'
    url = base_url_for(blocked_user_id)

    stub_request(:post, url)
      .with(
        headers: request_headers,
        query: { op: 'auth', password: alma_password, view: 'full' }
      )
      .to_return(status: 204, body: '', headers: {})

    stub_request(:get, url)
      .with(
        headers: request_headers,
        query: { expand: 'fees', view: 'full' }
      )
      .to_return(status: 200, body: File.new("spec/data/alma_patrons/#{blocked_user_id}.json"))

    post '/validate_proxy_patron', params: { alma_id: blocked_user_id, alma_password: }
    expect(response.status).to eq(403)
    expect(response.body).to include('Fail')
  end

end
