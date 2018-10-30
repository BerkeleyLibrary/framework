require 'test_helper'

class ScanRequestFormsControllerTest < ActionDispatch::IntegrationTest
  setup do
    VCR.insert_cassette 'patrons'
  end

  teardown do
    VCR.eject_cassette
  end

  def test_unauthenticated_users_must_login
    get new_scan_request_form_path
    assert_redirected_to login_path(url: new_scan_request_form_path)
  end

  def test_ucb_faculty_are_allowed
    with_login(:ucb_faculty) do
      get new_scan_request_form_path
      assert_response :ok
    end
  end

  def test_ucb_visiting_scholars_are_allowed
    with_login(:ucb_scholar) do
      get new_scan_request_form_path
      assert_response :ok
    end
  end

  def test_blocked_ucb_faculty_are_forbidden
    with_login(:ucb_blocked_faculty) do
      get new_scan_request_form_path
      assert_response :forbidden
    end
  end

  def test_ucb_grad_students_are_forbidden
    with_login(:ucb_grad_student) do
      get new_scan_request_form_path
      assert_response :forbidden
    end
  end

  def test_questions_link_goes_to_prntscan_email_list
    with_login(:ucb_scholar) do
      get new_scan_request_form_path
      assert_select('.page-footer .support-email[href=?]', 'mailto:prntscan@lists.berkeley.edu')
    end
  end
end
