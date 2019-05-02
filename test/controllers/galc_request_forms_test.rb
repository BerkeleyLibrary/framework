require 'test_helper'

class GalcRequestFormsControllerTest < ActionDispatch::IntegrationTest
  #Use the stubbed records in the omniauth.yml file to simulate logins
  setup do
    VCR.insert_cassette 'patrons'
  end

  teardown do
    VCR.eject_cassette
  end

  def test_unauthenticated_users_must_login
    get new_galc_request_form_path
    assert_redirected_to login_path(url: new_galc_request_form_path)
  end

  #Patron type Postdoc does not have access to the GALC request form
  def test_ineligible_user_not_allowed
    with_login(:ucb_postdoc) do
      get new_galc_request_form_path
      assert_response :forbidden
    end
  end

  #A test user who has one note in his/her Millenium account that includes the eligibility note
  def test_eligible_user
    with_login(:ucb_lib_staff) do
      get new_galc_request_form_path
      assert_response :ok
    end
  end

  #A test user who has multiple notes in his/her Millenium account, one of which includes the eligibility note
  # def test_eligible_user_multiple_notes
  #   with_login(:ucb_postdoc) do
  #     get new_galc_request_form_path
  #     assert_response :ok
  #   end
  # end

  #Patron type or affiliation are not within the specifications
  def test_forbidden_view_message_for_forbidden_user
    with_login(:ucb_postdoc) do
      get new_galc_request_form_path
      assert_response :forbidden
      assert_select "h1", /Forbidden/
      assert_select "p", /The Graphic Arts Loan Collection is only available to UC Berkeley students, faculty and staff/
    end
  end

  #User has correct patron type and affiliation but no GALC eligible note in patron account
  def test_forbidden_view_message_for_ineligible_user
    with_login(:ucb_grad_student) do
      get new_galc_request_form_path
      assert_response :forbidden
      assert_select "h1", /Ineligible/
      assert_select "p", /Sorry, you are not eligible for this service/
    end
  end

  def test_index_redirects_to_new
    with_login(:ucb_lib_staff) do
      get galc_request_forms_path
      assert_redirected_to "/forms/galc-agreement/new"
    end
  end

  def test_new_page_renders_with_correct_headline
    with_login(:ucb_lib_staff) do
      get new_galc_request_form_path
      assert_response :ok
      assert_select "h1", /Graphics Arts Loan Collection (GALC) - Borrowing Contract/
    end
  end

  def test_questions_link_goes_to_webman_email
    with_login(:ucb_lib_staff) do
      get new_galc_request_form_path
      assert_select '.page-footer .support-email[href=?]',
        'mailto:webman@library.berkeley.edu'
    end
  end

  def test_new_page_renders_with_correct_secondary_headers
    with_login(:ucb_lib_staff) do
      get new_galc_request_form_path
      assert_response :ok
      assert_select "h2", /Borrowing Guidelines/
      assert_select "h2", /Fines and Liability/
    end
  end

  def test_submit_button_text
    with_login(:ucb_lib_staff) do
      get new_galc_request_form_path
      assert_select 'form input[type="submit"][value="Submit"]'
    end
  end

  # def test_required_all_boxes_checked
  #   with_login(:ucb_lib_staff) do
  #     get new_galc_request_form_path
  #     assert_select "#galc_request_form_borrow_check[required=required]"
  #     assert_select "#galc_request_form_fine_check[required=required]"
  #   end
  # end

  # def test_redirect_to_confirmation_page_after_submit
  #   with_login(:ucb_lib_staff) do
  #     form_params = {
  #       galc_request_form: {
  #         patron_email: "ethomas@berkeley.edu",
  #         display_name: "Elissa Thomas",
  #       }
  #     }

  #     post "/forms/galc-agreement", params: form_params
  #     assert_redirected_to "/forms/galc-agreement/confirmed"
  #   end
  # end

end