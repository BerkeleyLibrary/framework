require 'test_helper'

class RoutesTest < ActionDispatch::IntegrationTest

  setup do
    VCR.insert_cassette 'patrons'
  end

  teardown do
    VCR.eject_cassette
  end

  def test_root_redirects_to_altmedia
    get "/"
    assert_redirected_to "/forms/altmedia/new"
  end

  def test_can_browse_to_homepage
    get "/home"
    assert_response :ok
  end

  def test_unauthenticated_users_must_login_to_access_admin_page
    get "/admin"
    assert_redirected_to login_path(url: admin_path)
  end

  def test_framework_admin_can_browse_admin_page
    with_login(:ucb_eligible_scan) do
      get "/admin"
      assert_response :ok
    end
  end

  def test_non_admins_cannot_browse_admin_page
    with_login(:ucb_scholar) do
      get "/admin"
      assert_response :forbidden
    end
  end

  def test_altmedia_requires_sign_in
    get "/forms/altmedia"
    assert_redirected_to login_path(url: '/forms/altmedia')
  end

  def test_ucop_borrow_request_is_routeable
    get "/forms/ucop-borrowing-card"
    assert_redirected_to "/forms/ucop-borrowing-card/new"
    follow_redirect!

    assert_response :ok
  end

  def test_redirect_logout_cas_logout_page
    get '/logout'
    return_url = "https://auth#{'-test' unless Rails.env.production?}.berkeley.edu/cas/logout"
    my_domain = "auth#{'-test' unless Rails.env.production?}.berkeley.edu"
    request.headers["HTTP_HOST"] = my_domain
    assert_redirected_to return_url
  end
end
