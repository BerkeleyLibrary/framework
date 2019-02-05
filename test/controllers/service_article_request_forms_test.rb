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
  #TO DO: ADD VALID UNDERGRAD USER TO OMNIAUTH.YML
  def test_ineligbile_undergrad_student_not_allowed
    skip("Need to add undergrad student user")
      with_login(:ucb_grad_student) do
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

  def test_questions_link_goes_to_privdesk_email
    with_login(:ucb_eligible_scan) do
      get new_service_article_request_form_path
      assert_select '.page-footer .support-email[href=?]',
        'mailto:privdesk@library.berkeley.edu'
    end
  end

end
