require 'test_helper'

class RoutesTest < ActionDispatch::IntegrationTest
  def test_root_redirects_to_altmedia
    get "/"
    assert_redirected_to "/forms/altmedia/new"
  end

  def test_can_browse_to_homepage
    get "/home"
    assert_response :ok
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

  def test_redirect_home_on_logout
    get '/logout'
    assert_redirected_to controller: :home
    follow_redirect!

    assert_select "h1", /Library Forms/
  end
end
