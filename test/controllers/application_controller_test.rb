require 'test_helper'

class ApplicationControllerTest < ActionDispatch::IntegrationTest
  def test_404_on_hidden_paths
    ENV["LIT_HIDDEN_PATHS"] = "/home /adm.*"
    get "/home"
    assert_response :not_found

    get "/admin"
    assert_response :not_found
  ensure
    ENV.delete("LIT_HIDDEN_PATHS")
    get "/home"
    assert_response :ok

    get "/admin"
    assert_response :redirect
  end
end
