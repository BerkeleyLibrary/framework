require 'rails_helper'

RSpec.describe 'OKComputer', type: :request do
  before { allow(Alma::User).to receive(:find).and_return(Alma::User.new) }

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
