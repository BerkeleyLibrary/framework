require 'rails_helper'

describe ValidateProxyPatronController, type: :system do
  let(:alma_api_key) { 'test-api-key' }
  let(:patron_id) { '10000001' }
  let(:patron_password) { 'fakepass' }

  before do
    allow(Rails.application.config).to receive(:alma_api_key).and_return(alma_api_key)

    # Stub the login:
    stub_request(:post, "https://api-na.hosted.exlibrisgroup.com/almaws/v1/users/#{patron_id}?op=auth&password=#{patron_password}&view=full")
      .with(headers: { 'Accept' => 'application/json', 'Authorization' => "apikey #{alma_api_key}" })
      .to_return(status: 204, body: '', headers: {})

    # Stub the api response:
    stub_request(:get, "https://api-na.hosted.exlibrisgroup.com/almaws/v1/users/#{patron_id}?expand=fees&view=full")
      .with(headers: { 'Accept' => 'application/json', 'Authorization' => "apikey #{alma_api_key}" })
      .to_return(status: 200, body: File.new('spec/data/alma_patrons/10000001.json'))
  end

  describe 'cross-site requests' do
    before do
      @was_protected = ActionController::Base.allow_forgery_protection
      ActionController::Base.allow_forgery_protection = true
    end

    after do
      ActionController::Base.allow_forgery_protection = @was_protected
    end

    it 'allows cross-site requests' do
      endpoint_url = BerkeleyLibrary::Util::URIs.append(
        Capybara.current_session.server_url,
        '/validate_proxy_patron'
      ).to_s
      response = RestClient.post(endpoint_url, { alma_id: patron_id, alma_password: patron_password })
      expect(response.code).to eq(200)
      expect(response.body).to include('Success')
    end
  end
end
