require 'test_helper'
 
class DoemoffStudyRoomUseFormsControllerTest < ActionDispatch::IntegrationTest
  #Use the stubbed records in the omniauth.yml file to simulate logins
  setup do
    VCR.insert_cassette 'patrons'
  end

  teardown do
    VCR.eject_cassette
  end

  def test_unauthenticated_users_must_login
    get new_doemoff_study_room_use_form_path
    assert_redirected_to login_path(url: new_doemoff_study_room_use_form_path)
  end

  # PTYPE = 1
  def test_user_allowed_undergrad
    with_login(:ucb_undergrad_student) do
      get new_doemoff_study_room_use_form_path
      assert_response :ok
    end
  end

  # PTYPE = 3
  def test_user_allowed_grad
    with_login(:ucb_grad_student) do
      get new_doemoff_study_room_use_form_path
      assert_response :ok
    end
  end

  # PTYPE = 4
  def test_user_allowed_faculty
    with_login(:ucb_faculty) do
      get new_doemoff_study_room_use_form_path
      assert_response :ok
    end
  end

  # PTYPE = 6
  def test_user_allowed_library_staff
    with_login(:ucb_lib_staff) do
      get new_doemoff_study_room_use_form_path
      assert_response :ok
    end
  end

  # PTYPE = 12
  def test_user_allowed_postdoc
    with_login(:ucb_postdoc) do
      get new_doemoff_study_room_use_form_path
      assert_response :ok
    end
  end

  # PTYPE = 22
  def test_user_allowed_visiting_scholar
    with_login(:ucb_scholar) do
      get new_doemoff_study_room_use_form_path
      assert_response :ok
    end
  end

  # PTYPE = 17
  def test_lbnl_academic_staff_not_allowed
    with_login(:ucb_lbnl_academic_staff) do
      get new_doemoff_study_room_use_form_path
      assert_response :forbidden
    end
  end

  def test_blocked_user_not_allowed
     with_login(:ucb_blocked_faculty) do
      get new_doemoff_study_room_use_form_path
      assert_response :forbidden
    end
  end

  def test_forbidden_view_message
    with_login(:ucb_lbnl_academic_staff) do
      get new_doemoff_study_room_use_form_path
      assert_response :forbidden
      assert_select "h1", /Forbidden/
      assert_select "p", /Only current UC Berkeley students, faculty, staff, post-docs and visiting scholars are eligible to use a Doe/
    end
  end

  #Check to see if the correct patron record is chosen when a user has a student and patron ids
  #TODO: Add a test user with SLE status who has 2 different Millennium accounts
  def test_valid_patron_record
    with_login(:ucb_eligible_scan) do |user_data|
      get new_doemoff_study_room_use_form_path

      assert_select '#doemoff_study_room_use_form_patron_id' do
        assert_select '[value=?]', user_data["extra"]["employeeNumber"]
      end
    end
  end

  def test_new_page_renders_with_correct_headline
    with_login(:ucb_lib_staff) do
      get new_doemoff_study_room_use_form_path
      assert_response :ok
      assert_select "h1", /Moffitt Study Room/
    end
  end

  def test_new_page_renders_with_correct_secondary_headers
    with_login(:ucb_lib_staff) do
      get new_doemoff_study_room_use_form_path
      assert_response :ok
      assert_select "h2", /Borrowing Guidelines/
      assert_select "h2", /Fines and Liability/
      assert_select "h2", /Studio Use Agreement/
    end
  end

  def test_questions_link_goes_to_privdesk_email
    with_login(:ucb_lib_staff) do
      get new_doemoff_study_room_use_form_path
      assert_select '.page-footer .support-email[href=?]',
        'mailto:privdesk@library.berkeley.edu'
    end
  end

  def test_patron_email_readonly
    with_login(:ucb_lib_staff) do |user_data|
      get new_doemoff_study_room_use_form_path

      assert_select '#doemoff_study_room_use_form_patron_email' do
        assert_select '[readonly=?]', 'readonly'
        assert_select '[value=?]', user_data["info"]["email"]
      end
    end
  end

  def test_patron_name_readonly
    with_login(:ucb_lib_staff) do |user_data|
      get new_doemoff_study_room_use_form_path

      assert_select '#doemoff_study_room_use_form_display_name' do
        assert_select '[readonly=?]', 'readonly'
        assert_select '[value=?]', user_data["info"]["displayName"]
      end
    end
  end

  def test_submit_button_text
    with_login(:ucb_lib_staff) do
      get new_doemoff_study_room_use_form_path
      assert_select 'form input[type="submit"][value="Submit"]'
    end
  end

  def test_success_if_all_boxes_checked_submission
    with_login(:ucb_lib_staff) do
      form_params = {
        doemoff_study_room_use_form: {
          borrow_check: "unchecked",
          roomUse_check: "checked",
          fines_check: "checked"
        }
      }

      post "/forms/doemoff-study-room-use", params: form_params
      assert_redirected_to new_doemoff_study_room_use_form_path(form_params)
      form_params[:doemoff_study_room_use_form][:borrow_check] = "checked"
      post "/forms/doemoff-study-room-use", params: form_params
      assert_redirected_to "/forms/doemoff-study-room-use/all_checked"
    end
  end

  def test_required_all_boxes_checked
    with_login(:ucb_lib_staff) do
      get new_doemoff_study_room_use_form_path
      assert_select "#doemoff_study_room_use_form_borrow_check[required=required]"
      assert_select "#doemoff_study_room_use_form_roomUse_check[required=required]"
      assert_select "#doemoff_study_room_use_form_fines_check[required=required]"
    end
  end
end
