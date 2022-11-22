require 'forms_helper'

describe 'Fines', type: :request do
  def base_url_for(user_id)
    "https://api-na.hosted.exlibrisgroup.com/almaws/v1/users/#{user_id}"
  end

  let(:alma_api_key) { 'totally-fake-key' }
  let(:request_headers) { { 'Accept' => 'application/json', 'Authorization' => "apikey #{alma_api_key}" } }

  before do
    allow(Rails.application.config).to receive(:alma_api_key).and_return(alma_api_key)
  end

  it 'throws a ParameterMissing error if request has no jwt' do
    expect { get fines_path }.to raise_error(ActionController::ParameterMissing)
  end

  it 'redirects to error page if request has a non-existant alma id' do
    user_id = '00000'
    stub_request(:get, "#{base_url_for(user_id)}/fees")
      .with(headers: request_headers)
      .to_return(status: 404, body: '')

    get '/fines?&jwt=totallyfakejwt'
    follow_redirect!
    expect(response.status).to eq(200)
    expect(response.body).to include('Error')
  end

  it 'list page with an existing alma id routes to index page' do
    user_id = '10335026'
    stub_request(:get, "#{base_url_for(user_id)}/fees")
      .with(headers: request_headers)
      .to_return(status: 200, body: File.new('spec/data/fines/alma-fees-list.json'))

    get "/fines?&jwt=#{File.read('spec/data/fines/alma-fees-jwt.txt')}"
    expect(response.body).to include('<h1>List of Fines + Fees</h1>')
    expect(response.body).to include('Lost item process fee')
  end

  it 'payments page lists fees to confirm payment' do
    user_id = '10335026'
    stub_request(:get, "#{base_url_for(user_id)}/fees")
      .with(headers: request_headers)
      .to_return(status: 200, body: File.new('spec/data/fines/alma-fees-list.json'))

    post '/fines/payment', params: { alma_id: user_id, fine: { payment: ['3260566220006532'] } }
    expect(response.status).to eq(200)
    expect(response.body).to include('<h1>Confirm Fees to Pay</h1>')
    expect(response.body).to include('Lost item process fee')
    expect(response.body).to include('Total Payment: $10.00')
  end

  it 'payments page redirects to index if no fee was selected for payment' do
    post '/fines/payment', params: { jwt: File.read('spec/data/fines/alma-fees-jwt.txt') }
    expect(response.status).to eq(302)
    expect(response).to redirect_to("#{fines_path}?jwt=#{File.read('spec/data/fines/alma-fees-jwt.txt')}")
  end

  it 'successful transaction_complete returns status 200' do
    user_id = '10335026'
    stub_request(:post, "#{base_url_for(user_id)}/fees/3260566220006532")
      .with(
        headers: request_headers,
        query: { amount: '10.00', external_transaction_id: nil, method: 'ONLINE', op: 'pay' }
      )
      .to_return(status: 200, body: '', headers: {})

    stub_request(:get, "#{base_url_for(user_id)}/fees")
      .with(headers: request_headers)
      .to_return(status: 200, body: File.new('spec/data/fines/alma-fees-list.json'))

    post '/fines/transaction_complete', params: { RESULT: '0', USER1: user_id, USER2: ['3260566220006532'] }
    expect(response.status).to eq(200)
  end

  it 'unsuccessful transaction_complete returns status 500' do
    post '/fines/transaction_complete', params: { RESULT: '100', USER1: '10335026', USER2: ['3260566220006532'] }
    expect(response.status).to eq(500)
  end

  it 'fail page renders' do
    get fines_transaction_fail_path
    expect(response.status).to eq(200)
    expect(response.body).to include('Payment Failed')
  end

  it 'error page renders' do
    get fines_transaction_error_path
    expect(response.status).to eq(200)
    expect(response.body).to include('Error')
  end
end
