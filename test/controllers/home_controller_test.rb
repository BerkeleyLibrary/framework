require 'test_helper'

class HomeControllerTest < ActionDispatch::IntegrationTest
  setup { VCR.insert_cassette 'patrons' }
  teardown { VCR.eject_cassette }

  test "404 on hidden paths" do
    begin
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

  test "/health warns on patron api okay" do
    get "/health"
    assert_response :ok
    assert_equal JSON.parse(response.body), {
      "status" => "pass",
      "details" => {
        "patron_api:find" => {
          "status" => "pass",
        }
      }
    }
  end

  test "/health warns on patron api error" do
    Patron::Record.stub(:find, -> (id) { raise "Something went wrong" }) do
      get "/health"
      assert_response :too_many_requests
      assert_equal JSON.parse(response.body), {
        "status" => "warn",
        "details" => {
          "patron_api:find" => {
            "status" => "warn",
            "output" => "RuntimeError",
          }
        }
      }
    end
  end
end
