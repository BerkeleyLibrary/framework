require 'test_helper'

class ServiceArticleRequestFormsControllerTest < ActionDispatch::IntegrationTest
  #Use the stubbed records in the omniauth.yml file to simulate logins
  setup do
    VCR.insert_cassette 'patrons'
  end

  teardown do
    VCR.eject_cassette
  end

  def test_unauthenticated_users_must_login
    get new_service_article_request_form_path
    assert_redirected_to login_path(url: new_service_article_request_form_path)
  end

   #Occasionally someone will have a CalNet account for login but no Millennium patron records
  def test_forbidden_if_missing_patron_record
    with_login(:ucb_faculty_no_patron_record) do
      get new_service_article_request_form_path
      assert_response :forbidden
    end
  end

  #This particular test user does not have scan access
  def test_ineligible_faculty_not_allowed
    with_login(:ucb_faculty) do
      get new_service_article_request_form_path
      assert_response :forbidden
    end
  end

  #This particular test user does not have scan access
  def test_ineligbile_grad_student_not_allowed
    with_login(:ucb_grad_student) do
      get new_service_article_request_form_path
      assert_response :forbidden
    end
  end

  #This particular test user does not have scan access
  def test_ineligible_undergrad_student_not_allowed
    with_login(:ucb_undergrad_student) do
      get new_service_article_request_form_path
      assert_response :forbidden
    end
  end

  #A test user who does not have scan access and is not student or faculty
  def test_ineligible_other_not_allowed
    with_login(:ucb_scholar) do
      get new_service_article_request_form_path
      assert_response :forbidden
    end
  end

  #A test user who has one note in his/her Millenium account that includes the eligibility note
  def test_eligible_user
    with_login(:ucb_eligible_scan) do
      get new_service_article_request_form_path
      assert_response :ok
    end
  end

  #A test user who has multiple notes in his/her Millenium account, one of which includes the eligibility note
  def test_eligible_user_multiple_notes
    with_login(:ucb_postdoc) do
      get new_service_article_request_form_path
      assert_response :ok
    end
  end

  def test_forbidden_view_message_for_user_ineligible_faculty
    with_login(:ucb_faculty) do
      get new_service_article_request_form_path
      assert_response :forbidden
      assert_select "h1", /More is required/
      assert_select "p", /Sorry, you have not filled out the Opt in/
    end
  end

  def test_forbidden_view_message_for_user_ineligible_grad_student
    with_login(:ucb_grad_student) do
      get new_service_article_request_form_path
      assert_response :forbidden
      assert_select "h1", /Ineligible/
      assert_select "p", /Sorry, you are not eligible for this service/
    end
  end

  def test_forbidden_view_message_for_user_ineligible_other
    with_login(:ucb_lib_staff) do
      get new_service_article_request_form_path
      assert_response :forbidden
      assert_select "h1", /Ineligible/
      assert_select "p", /Sorry, you are not eligible for this service/
    end
  end

  def test_index_redirects_to_new
    with_login(:ucb_eligible_scan) do
      get service_article_request_forms_path
      assert_redirected_to "/forms/altmedia-articles/new"
    end
  end

  def test_new_page_renders_with_correct_headline
    with_login(:ucb_eligible_scan) do
      get new_service_article_request_form_path
      assert_response :ok
      assert_select "h1", /Library Alt-Media Service - Article Request Form/
    end
  end

  def test_questions_link_goes_to_baker_email
    with_login(:ucb_eligible_scan) do
      get new_service_article_request_form_path
      assert_select '.page-footer .support-email[href=?]',
        'mailto:baker@library.berkeley.edu'
    end
  end

  def test_new_page_renders_with_correct_secondary_headers
    with_login(:ucb_eligible_scan) do
      get new_service_article_request_form_path
      assert_response :ok
      assert_select "h2", /Patron Information/
      assert_select "h2", /Journal Information/
    end
  end

  def test_patron_email_required_with_value
    with_login(:ucb_eligible_scan) do |user_data|
      get new_service_article_request_form_path

      assert_select '#service_article_request_form_patron_email' do
        assert_select '[required=?]', 'required'
        assert_select '[value=?]', user_data["info"]["email"]
      end
    end
  end

  def test_patron_name_required_with_value
    with_login(:ucb_eligible_scan) do |user_data|
      get new_service_article_request_form_path

      assert_select '#service_article_request_form_display_name' do
        assert_select '[required=?]', 'required'
        assert_select '[value=?]', user_data["info"]["displayName"]
      end
    end
  end

  def test_submit_button_text
    with_login(:ucb_eligible_scan) do
      get new_service_article_request_form_path
      assert_select 'form input[type="submit"][value="Submit"]'
    end
  end

  def test_specified_article_fields_are_required
    with_login(:ucb_eligible_scan) do
      get new_service_article_request_form_path
      assert_select "#service_article_request_form_pub_title[required=required]"
      assert_select "#service_article_request_form_article_title[required=required]"
      assert_select "#service_article_request_form_vol[required=required]"
    end
  end

  def test_redirect_to_confirmation_page_after_submit
    #Mock up a form with article metadata to send
    with_login(:ucb_eligible_scan) do
      form_params = {
        service_article_request_form: {
          patron_email: "ethomas@berkeley.edu",
          display_name: "Elissa Thomas",
          pub_title: "A Test Publication",
          article_title: "Exciting scholarly article title",
          vol: "3",
          citation: "Davis, K. Exciting scholarly article title. A Test Publication: 3"
        }
      }

      post "/forms/altmedia-articles", params: form_params
      assert_redirected_to "/forms/altmedia-articles/confirmed"
    end
  end

end
