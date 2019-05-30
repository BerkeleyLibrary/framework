require 'test_helper'

class StudentEdevicesLoanFormsControllerTest < ActionDispatch::IntegrationTest
  #Use the stubbed records in the omniauth.yml file to simulate logins
  setup do
    VCR.insert_cassette 'patrons'
  end

  teardown do
    VCR.eject_cassette
  end

  def test_unauthenticated_users_must_login
    get new_student_edevices_loan_form_path
    assert_redirected_to login_path(url: new_student_edevices_loan_form_path)
  end

  def test_undergrad_student_user_allowed
    with_login(:ucb_undergrad_student) do
      get new_student_edevices_loan_form_path
      assert_response :ok
    end
  end

  def test_grad_student_user_allowed
    with_login(:ucb_grad_student) do
      get new_student_edevices_loan_form_path
      assert_response :ok
    end
  end

  def test_non_student_not_allowed
    with_login(:ucb_scholar) do
      get new_student_edevices_loan_form_path
      assert_response :forbidden
    end
  end

   def test_blocked_user_not_allowed
     with_login(:ucb_blocked_faculty) do
      get new_student_edevices_loan_form_path
      assert_response :forbidden
    end
  end

  def test_index_redirects_to_new
    with_login(:ucb_undergrad_student) do
      get student_edevices_loan_forms_path
      assert_redirected_to "/forms/student_edevices_loan/new"
    end
  end

  #Check to see if the correct patron record is chosen when a user has a student and patron ids
  #TODO: Add a test user with SLE status who has 2 different Millennium accounts
  def test_valid_student_record
    with_login(:ucb_undergrad_student) do |user_data|
      get new_student_edevices_loan_form_path

      assert_select '#student_edevices_loan_form_patron_id' do
        assert_select '[value=?]', user_data["extra"]["berkeleyEduStuID"]
      end
    end
  end

  def test_forbidden_view_message
    with_login(:ucb_scholar) do
      get new_student_edevices_loan_form_path
      assert_response :forbidden
      assert_select "h1", /Forbidden/
      assert_select "p", /The Student Electronic Devices Loan Program is only available to registered UC Berkeley Students/
    end
  end

  def test_new_page_renders_with_correct_headline
    with_login(:ucb_undergrad_student) do
      get new_student_edevices_loan_form_path
      assert_response :ok
      assert_select "h1", /Student Electronic Devices Loan/
    end
  end

  def test_new_page_renders_with_correct_secondary_headers
    with_login(:ucb_undergrad_student) do
      get new_student_edevices_loan_form_path
      assert_response :ok
      assert_select "h2", /Borrowing Guidelines/
      assert_select "h2", /Student Lending Program Loan Period/
      assert_select "h2", /Fines and Liability/
      assert_select "h2", /Electronic Devices Loan Agreement/
    end
  end

  def test_questions_link_goes_to_privdesk_email
    with_login(:ucb_undergrad_student) do
      get new_student_edevices_loan_form_path
      assert_select '.page-footer .support-email[href=?]',
        'mailto:privdesk@library.berkeley.edu'
    end
  end

  def test_patron_email_readonly
    with_login(:ucb_undergrad_student) do |user_data|
      get new_student_edevices_loan_form_path

      assert_select '#student_edevices_loan_form_patron_email' do
        assert_select '[readonly=?]', 'readonly'
        assert_select '[value=?]', user_data["info"]["email"]
      end
    end
  end

  def test_patron_name_readonly
    with_login(:ucb_undergrad_student) do |user_data|
      get new_student_edevices_loan_form_path

      assert_select '#student_edevices_loan_form_display_name' do
        assert_select '[readonly=?]', 'readonly'
        assert_select '[value=?]', user_data["extra"]["displayName"]
      end
    end
  end

  def test_submit_button_text
    with_login(:ucb_undergrad_student) do
      get new_student_edevices_loan_form_path
      assert_select 'form input[type="submit"][value="Submit"]'
    end
  end

  def test_success_if_all_boxes_checked_submission
    skip("Need to figure out why the error is 503 Service Unavailable")
      with_login(:ucb_grad_student) do
        form_params = {
          student_edevices_loan_form: {
            borrow_check: "unchecked",
            lend_check: "checked",
            fines_check: "checked",
            edev_check: "checked"
          }
        }

        post "/forms/student_edevices_loan", params: form_params
        assert_redirected_to new_student_edevices_loan_form_path(form_params)
        form_params[:student_edevices_loan_form][:borrow_check] = "checked"
        post "/forms/student_edevices_loan", params: form_params
        assert_redirected_to "/forms/student_edevices_loan/all_checked"
    end
  end

  def test_required_all_boxes_checked
    with_login(:ucb_undergrad_student) do
      get new_student_edevices_loan_form_path
      assert_select "#student_edevices_loan_form_borrow_check[required=required]"
      assert_select "#student_edevices_loan_form_lend_check[required=required]"
      assert_select "#student_edevices_loan_form_fines_check[required=required]"
      assert_select "#student_edevices_loan_form_edev_check[required=required]"
    end
  end
end
