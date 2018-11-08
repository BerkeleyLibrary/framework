require 'test_helper'

class CampusNetworksControllerTest < ActionDispatch::IntegrationTest
  setup do
    VCR.insert_cassette 'nettools'
  end

  teardown do
    VCR.eject_cassette
  end

  def test_renders_the_different_formats
    get '/campus-networks'
    assert_response :ok
    assert_match /UCB \+ LBL IP Addresses/m, @response.body

    get '/campus-networks/ucb'
    assert_response :ok
    assert_match /UCB-only IP Addresses/m, @response.body

    get '/campus-networks/lbl'
    assert_response :ok
    assert_match /LBL-only IP Addresses/m, @response.body
  end
end
