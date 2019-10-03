require 'calnet_helper'

describe SessionsController, type: :request do
  it 'logs CalNet/Omniauth parameters as JSON' do
    patron_id = Patron::FRAMEWORK_ADMIN_ID
    log = capturing_log { with_login(patron_id) { get admin_path } }
    lines = log.lines

    expected_msg = 'Received omniauth callback'
    log_line = lines.find { |line| line.include?(expected_msg) }
    result = JSON.parse(log_line)
    expect(result['msg']).to eq(expected_msg)
    omniauth_hash = result['omniauth']
    expect(omniauth_hash['provider']).to eq('calnet') # just a smoke test
    expect(omniauth_hash['extra']['employeeNumber']).to eq(patron_id)
  end
end
