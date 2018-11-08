require 'test_helper'

class CampusNetworksControllerTest < ActionDispatch::IntegrationTest
  setup do
    VCR.insert_cassette 'nettools'
  end

  teardown do
    VCR.eject_cassette
  end

  def test_campus_networks_route_is_hyphen_separated
    assert_equal campus_networks_path, '/campus-networks'
  end

  def test_renders_the_different_formats
    get campus_networks_path
    assert_response :ok
    assert_match /UCB \+ LBL IP Addresses/m, @response.body

    get campus_networks_path(organization: "lbl")
    assert_response :ok
    assert_match /LBL-only IP Addresses/m, @response.body

    get campus_networks_path(organization: "ucb")
    assert_response :ok
    assert_match /UCB-only IP Addresses/m, @response.body
  end
end
