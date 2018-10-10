require 'test_helper'

class RoutesTest < ActionDispatch::IntegrationTest
  def test_root_redirects_to_altmedia
    get "/"
    assert_redirected_to "/forms/altmedia/new"
  end

  def test_home_displays_form_links
    get "/home"
    assert_response :ok
    assert_select 'ul#webforms'
    assert_select 'nav', /UCOP Employee Borrowing Cards/
    assert_select 'nav', /Faculty Alt-Media Scanning/
  end

  def test_altmedia_requires_sign_in
    get "/forms/altmedia"
    assert_redirected_to "/sign_in"
  end

  def test_ucop_form_page
    get "/forms/ucop-borrowing-card"
    assert_redirected_to "/forms/ucop-borrowing-card/new"
    follow_redirect!

    assert_response :ok
    assert_select "h1", 'UC Berkeley Library Access to Library Resources for Select UCOP Staff'
  end
end
