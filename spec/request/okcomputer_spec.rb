require 'rails_helper'

RSpec.describe 'OKComputer', type: :request do
  before do
    allow(Alma::User).to receive(:find).and_return(Alma::User.new)
    tind_health_check_url = "#{Rails.application.config.tind_base_uri}api/v1/search?In=en"
    stub_request(:head, tind_health_check_url).to_return(status: 200)
    stub_request(:head, Rails.application.config.whois_health_check_url).to_return(status: 200)
    stub_request(:head, Rails.application.config.hathiTrust_health_check_url).to_return(status: 200)
    stub_request(:head, Rails.application.config.berkeley_service_now_health_check_url).to_return(status: 200)
    stub_request(:get, Rails.application.config.paypal_payflow_url).to_return(status: 200)
  end

  it 'is mounted at /okcomputer' do
    get '/okcomputer'
    expect(response).to have_http_status :ok
  end

  it 'returns all checks to /health' do

    get '/health'
    expect(response.parsed_body.keys).to match_array %w[
      action-mailer
      alma-patron-lookup
      default
      database
      database-migrations
      thind-api
      whois-arin-api
      paypal-payflow
      hathitrust-api
      berkeley-service-now
    ]
    pending 'https://github.com/emmahsax/okcomputer/pull/21'
    expect(response).to have_http_status :ok
  end

  it 'fails when Alma lookups fail' do
    expect(Alma::User).to receive(:find).and_raise('Uh oh!')
    get '/health'
    expect(response).not_to have_http_status :ok
  end
end
