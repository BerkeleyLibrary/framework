require 'rails_helper'

RSpec.describe 'altmedia configuration' do

  def with_location_requests_max_oclc_numbers(max_oclc_numbers)
    env_var = 'FRAMEWORK_LOCATION_REQUESTS_MAX_OCLC_NUMBERS'
    original_max_oclc_numbers = ENV.fetch(env_var, nil)
    set_env(env_var, max_oclc_numbers)
    yield
  ensure
    set_env(env_var, original_max_oclc_numbers)
  end

  def set_env(env_var, value)
    value ? ENV[env_var] = value : ENV.delete(env_var)
  end

  def altmedia_config
    Rails.application.config_for(:altmedia)
  end

  it 'defaults the location requests max OCLC numbers to 10,000' do
    with_location_requests_max_oclc_numbers(nil) do
      expect(altmedia_config[:location_requests_max_oclc_numbers]).to eq(10_000)
    end
  end

  it 'reads the location requests max OCLC numbers from FRAMEWORK_LOCATION_REQUESTS_MAX_OCLC_NUMBERS' do
    with_location_requests_max_oclc_numbers('123') do
      expect(altmedia_config[:location_requests_max_oclc_numbers]).to eq(123)
    end
  end

  it 'exposes the location requests max OCLC numbers through Rails configuration' do
    expect(Rails.application.config.location_requests_max_oclc_numbers).to eq(Rails.application.config.altmedia[:location_requests_max_oclc_numbers])
  end
end
