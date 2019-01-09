require 'test_helper'

class LibstaffEdevicesLoanFormsControllerTest < ActionDispatch::IntegrationTest
  #Use the stubbed records in the omniauth.yml file to simulate logins
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

  def test_non_library_staff_not_allowed
    with_login(:ucb_scholar) do
      get new_libstaff_edevices_loan_form_path
      assert_response :forbidden
    end
  end

  def test_blocked_user_not_allowed
    with_login(:ucb_blocked_faculty) do
      get new_libstaff_edevices_loan_form_path
      assert_response :forbidden
    end
  end

  def test_index_redirects_to_new
    with_login(:ucb_lib_staff) do
      get libstaff_edevices_loan_forms_path
      assert_redirected_to "/forms/library-staff-devices/new"
    end
  end

  def test_forbidden_view_message
    with_login(:ucb_scholar) do
      get new_libstaff_edevices_loan_form_path
      assert_response :forbidden
      assert_select "h1", /Only Library Staff are eligible to borrow an electronic device/
    end
  end

  #Need a valid community college user in the omniauth.yml file for testing
  #There are basically no users that could be CC-affiliated with CalNet IDs, so this is an edge case
  # def test_unaffiliated_user_not_allowed
  #   with_login(:community_college_user) do
  #     get new_libstaff_edevices_loan_form_path
  #     assert_response :forbidden
  #   end
  # end

  def test_new_page_renders_with_correct_headline
    with_login(:ucb_lib_staff) do
      get new_libstaff_edevices_loan_form_path
      assert_response :ok
      assert_select "h1", /Library Staff Electronic Devices Loan/
    end
  end

  def test_new_page_renders_with_correct_secondary_headers
    with_login(:ucb_lib_staff) do
      get new_libstaff_edevices_loan_form_path
      assert_response :ok
      assert_select "h2", /Borrowing Guidelines/
      assert_select "h2", /Library Staff Lending Program Loan Periods/
      assert_select "h2", /Fines and Liability/
      assert_select "h2", /Electronic Devices Loan Agreement/
    end
  end

  def test_questions_link_goes_to_privdesk_email
    with_login(:ucb_lib_staff) do
      get new_libstaff_edevices_loan_form_path
      assert_select '.page-footer .support-email[href=?]',
        'mailto:privdesk@library.berkeley.edu'
    end
  end

  def test_staff_name_readonly
    with_login(:ucb_lib_staff) do
      get new_libstaff_edevices_loan_form_path
      assert_select "input:match('id', ?)", /libstaff_edevices_loan_form_full_name/ do |elements|
        assert_select "[readonly=?]", "readonly"
      end
    end
  end

  def test_staff_name_retrieved
    with_login(:ucb_lib_staff) do
      get new_libstaff_edevices_loan_form_path
      mock_hash = retrieve_mock_user_hash(:ucb_lib_staff)
      employee_name = mock_hash["extra"]["displayName"]
      assert_select "input:match('id', ?)", /libstaff_edevices_loan_form_full_name/ do |elements|
        assert_select "[value=?]", employee_name
      end
    end
  end

  def test_staff_email_hidden_field_passed
    with_login(:ucb_lib_staff) do
      get new_libstaff_edevices_loan_form_path
      mock_hash = retrieve_mock_user_hash(:ucb_lib_staff)
      employee_email = mock_hash["info"]["email"]
      assert_select "input:match('id', ?)", /libstaff_edevices_loan_form_staff_email/ do |elements|
        assert_select "[value=?]", employee_email
        assert_select "[type=?]", "hidden"
      end
    end
  end

  def test_staff_id_hidden_field_passed
    with_login(:ucb_lib_staff) do
      get new_libstaff_edevices_loan_form_path
      mock_hash = retrieve_mock_user_hash(:ucb_lib_staff)
      employee_id = mock_hash["extra"]["employeeNumber"]
      assert_select "input:match('id', ?)", /libstaff_edevices_loan_form_staff_id_number/ do |elements|
        assert_select "[value=?]", employee_id
        assert_select "[type=?]", "hidden"
      end
    end
  end

  def test_today_date_hidden_field_passed
    with_login(:ucb_lib_staff) do
      get new_libstaff_edevices_loan_form_path
      d = DateTime.now
      sign_date = d.strftime("%m/%d/%Y")
      assert_select "input:match('id', ?)", /libstaff_edevices_loan_form_today_date/ do |elements|
        assert_select "[value=?]", sign_date
        assert_select "[type=?]", "hidden"
      end
    end
  end

  def test_submit_button_text
    with_login(:ucb_lib_staff) do
      get new_libstaff_edevices_loan_form_path
      assert_select 'form input[type="submit"][value="Submit"]'
    end
  end

  def test_no_reset_button
    with_login(:ucb_lib_staff) do
      get new_libstaff_edevices_loan_form_path
      assert_select 'form input[type="reset"]', {count: 0}
    end
  end

  def test_success_if_all_boxes_checked_submission
    with_login(:ucb_lib_staff) do
      get new_libstaff_edevices_loan_form_path
      post "/forms/library-staff-devices", params: { libstaff_edevices_loan_form: { borrow_check: "checked", lending_check: "checked", fines_check: "checked", edevices_check: "checked" } }
      #All 4 boxes must be checked to get to confirmation page
      assert_redirected_to "/forms/library-staff-devices/all_check"
    end
  end

  def test_required_all_boxes_checked
    with_login(:ucb_lib_staff) do
      get new_libstaff_edevices_loan_form_path
      assert_select "#libstaff_edevices_loan_form_borrow_check[required=required]"
      assert_select "#libstaff_edevices_loan_form_lending_check[required=required]"
      assert_select "#libstaff_edevices_loan_form_fines_check[required=required]"
      assert_select "#libstaff_edevices_loan_form_edevices_check[required=required]"
    end
  end

end