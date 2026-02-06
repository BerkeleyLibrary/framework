require 'rails_helper'

RSpec.describe 'OKComputer', type: :request do
  before do
    allow(Alma::User).to receive(:find).and_return(Alma::User.new)
    tind_health_check_url = "#{Rails.application.config.tind_base_uri}api/v1/search?In=en"
    stub_request(:head, tind_health_check_url).to_return(status: 200)
    stub_request(:head, Rails.application.config.x.healthcheck_urls.whois).to_return(status: 200)
    stub_request(:head, Rails.application.config.x.healthcheck_urls.hathiTrust).to_return(status: 200)
    stub_request(:head, Rails.application.config.x.healthcheck_urls.berkeley_service_now).to_return(status: 200)
    stub_request(:get, Rails.application.config.paypal_payflow_url).to_return(status: 200)
  end

  it 'is mounted at /okcomputer' do
    get '/okcomputer'
    expect(response).to have_http_status :ok
  end

  context 'without SMTP enabled' do
    before do
      allow(ActionMailer::Base).to receive(:delivery_method).and_return(:test)

      OkComputer::Registry.instance_variable_set(:@checks, {})
      load Rails.root.join('config/initializers/okcomputer.rb')
    end

    it 'returns checks to /health' do
      get '/health'
      expect(response.parsed_body.keys).to match_array %w[
        default
        database
        alma-patron-lookup
        database-migrations
        tind-api
        whois-arin-api
        paypal-payflow
        hathitrust-api
        berkeley-service-now
      ]
    end
  end

  context 'with SMTP enabled' do
    before do
      allow(ActionMailer::Base).to receive(:delivery_method).and_return(:smtp)
      allow(Net::SMTP).to receive(:start)

      OkComputer::Registry.instance_variable_set(:@checks, {})
      load Rails.root.join('config/initializers/okcomputer.rb')
    end

    it 'returns all checks to /health' do
      get '/health'
      expect(response.parsed_body.keys).to match_array %w[
        default
        database
        alma-patron-lookup
        database-migrations
        tind-api
        whois-arin-api
        paypal-payflow
        hathitrust-api
        berkeley-service-now
        mail-connectivity
      ]
    end
  end

  context 'when Alma lookups fail' do
    it 'returns a non-200 response' do
      expect(Alma::User).to receive(:find).and_raise('Uh oh!')
      get '/health'
      expect(response).not_to have_http_status :ok
    end
  end

end
