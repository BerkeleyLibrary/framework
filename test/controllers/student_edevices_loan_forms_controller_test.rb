require 'test_helper'

class StudentEdevicesLoanFormsControllerTest < ActionDispatch::IntegrationTest
  # TODO: Add a test user with SLE status who has 2 different Millennium accounts
  ALLOWED_USERS = [
    :ucb_grad_student,
    :ucb_undergrad_student,
  ]

  FORBIDDEN_USERS = [
    :ucb_blocked_faculty,
    :ucb_scholar, # Test with a user with a PType that is not 1, 2, or 3
  ]

  setup    { VCR.insert_cassette 'patrons' }
  teardown { VCR.eject_cassette }

  # Occasionally someone will have a CalNet account for login but no Millennium
  # patron records
  test "forbidden_if_missing_patron_record" do
    with_login(:ucb_faculty_no_patron_record) do
      get new_student_edevices_loan_form_path
      assert_response :forbidden
    end
  end

  test "unauthenticated_users_must_login" do
    get new_student_edevices_loan_form_path
    assert_redirected_to login_path(url: new_student_edevices_loan_form_path)
  end

  ALLOWED_USERS.each do |user_fixture|
    test "#{user_fixture}_allowed" do
      with_login(user_fixture) do |user_data|
        get new_student_edevices_loan_form_path
        assert_response :ok
        assert_select "h1", /Student Electronic Devices Loan/
        assert_select "h2", /Borrowing Guidelines/
        assert_select "h2", /Student Lending Program Loan Period/
        assert_select "h2", /Fines and Liability/
        assert_select "h2", /Electronic Devices Loan Agreement/
        assert_select "#student_edevices_loan_form_borrow_check[required=required]"
        assert_select "#student_edevices_loan_form_lend_check[required=required]"
        assert_select "#student_edevices_loan_form_fines_check[required=required]"
        assert_select "#student_edevices_loan_form_edev_check[required=required]"
        assert_select 'form input[type="submit"][value="Submit"]'
        assert_select '.page-footer .support-email[href=?]', 'mailto:privdesk@library.berkeley.edu'

        assert_select '#student_edevices_loan_form_patron_email' do
          assert_select '[readonly=?]', 'readonly'
          assert_select '[value=?]', user_data["info"]["email"]
        end

        assert_select '#student_edevices_loan_form_display_name' do
          assert_select '[readonly=?]', 'readonly'
          assert_select '[value=?]', user_data["extra"]["displayName"]
        end
      end
    end
  end

  FORBIDDEN_USERS.each do |user_fixture|
    test "#{user_fixture}_forbidden" do
      with_login(user_fixture) do
        get new_student_edevices_loan_form_path
        assert_response :forbidden
        assert_select "h1", /Forbidden/
        assert_select "p", /The Student Electronic Devices Loan Program is only available to UC Berkeley Students/
      end
    end
  end

  test "index_redirects_to_new" do
    with_login(:ucb_undergrad_student) do
      get student_edevices_loan_forms_path
      assert_redirected_to "/forms/student_edevices_loan/new"
    end
  end

  # Check to see if the correct patron record is chosen when a user has a
  # student and patron ids
  #
  # TODO: This test does not seem to work with the ucb_grad_student fixture!
  test "valid_student_record" do
    with_login(:ucb_undergrad_student) do |user_data|
      get new_student_edevices_loan_form_path
      assert_select '#student_edevices_loan_form_patron_id' do
        assert_select '[value=?]', user_data["extra"]["berkeleyEduStuID"]
      end
    end
  end

  test "required_all_boxes_checked" do
    with_login(:ucb_undergrad_student) do
      post "/forms/student_edevices_loan", params: params = {
        student_edevices_loan_form: {
          borrow_check: "unchecked",
          lend_check: "checked",
          fines_check: "checked",
          edev_check: "checked",
        }
      }
      assert_redirected_to new_student_edevices_loan_form_path(params)
    end
  end

  test "success_if_all_boxes_checked_submission" do
    with_login(:ucb_grad_student) do
      post "/forms/student_edevices_loan", params: {
        student_edevices_loan_form: {
          borrow_check: "checked",
          lend_check: "checked",
          fines_check: "checked",
          edev_check: "checked",
        }
      }
      assert_redirected_to "/forms/student_edevices_loan/all_checked"
    end
  end
end
