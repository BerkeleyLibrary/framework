require 'test_helper'

class StudentEdevicesLoanFormsControllerTest < ActionDispatch::IntegrationTest
  #Use the stubbed records in the omniauth.yml file to simulate logins
  setup do
    VCR.insert_cassette 'patrons'
  end

  teardown do
    VCR.eject_cassette
  end

  # def test_unauthenticated_users_must_login
  #   get new_scan_request_form_path
  #   assert_redirected_to login_path(url: new_scan_request_form_path)
  # end

  def test_user_allowed
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

  # def test_forbidden_view_message
  #   with_login(:ucb_scholar) do
  #     get new_student_edevices_loan_form_path
  #     assert_response :forbidden
  #     assert_select "h1", /Forbidden/
  #     assert_select "p", /Only Library Staff are eligible to borrow an electronic device/
  #   end
  # end

#   #Need a valid community college user in the omniauth.yml file for testing
#   #There are basically no users that could be CC-affiliated with CalNet IDs, so this is an edge case
#   # def test_unaffiliated_user_not_allowed
#   #   with_login(:community_college_user) do
#   #     get new_libstaff_edevices_loan_form_path
#   #     assert_response :forbidden
#   #   end
#   # end

#   def test_new_page_renders_with_correct_headline
#     with_login(:ucb_lib_staff) do
#       get new_libstaff_edevices_loan_form_path
#       assert_response :ok
#       assert_select "h1", /Library Staff Electronic Devices Loan/
#     end
#   end

#   def test_new_page_renders_with_correct_secondary_headers
#     with_login(:ucb_lib_staff) do
#       get new_libstaff_edevices_loan_form_path
#       assert_response :ok
#       assert_select "h2", /Borrowing Guidelines/
#       assert_select "h2", /Library Staff Lending Program Loan Periods/
#       assert_select "h2", /Fines and Liability/
#       assert_select "h2", /Electronic Devices Loan Agreement/
#     end
#   end

#   def test_questions_link_goes_to_privdesk_email
#     with_login(:ucb_lib_staff) do
#       get new_libstaff_edevices_loan_form_path
#       assert_select '.page-footer .support-email[href=?]',
#         'mailto:privdesk@library.berkeley.edu'
#     end
#   end

#   def test_patron_email_readonly
#     with_login(:ucb_lib_staff) do |user_data|
#       get new_libstaff_edevices_loan_form_path

#       assert_select '#libstaff_edevices_loan_form_patron_email' do
#         assert_select '[readonly=?]', 'readonly'
#         assert_select '[value=?]', user_data["info"]["email"]
#       end
#     end
#   end

#   def test_patron_name_readonly
#     with_login(:ucb_lib_staff) do |user_data|
#       get new_libstaff_edevices_loan_form_path

#       assert_select '#libstaff_edevices_loan_form_display_name' do
#         assert_select '[readonly=?]', 'readonly'
#         assert_select '[value=?]', user_data["info"]["displayName"]
#       end
#     end
#   end

#   def test_submit_button_text
#     with_login(:ucb_lib_staff) do
#       get new_libstaff_edevices_loan_form_path
#       assert_select 'form input[type="submit"][value="Submit"]'
#     end
#   end

#   def test_no_reset_button
#     with_login(:ucb_lib_staff) do
#       get new_libstaff_edevices_loan_form_path
#       assert_select 'form input[type="reset"]', {count: 0}
#     end
#   end

#   def test_success_if_all_boxes_checked_submission
#     with_login(:ucb_lib_staff) do
#       form_params = {
#         libstaff_edevices_loan_form: {
#           borrow_check: "unchecked",
#           lending_check: "checked",
#           fines_check: "checked",
#           edevices_check: "checked"
#         }
#       }

#       post "/forms/library-staff-devices", params: form_params
#       assert_redirected_to new_libstaff_edevices_loan_form_path(form_params)

#       form_params[:libstaff_edevices_loan_form][:borrow_check] = "checked"
#       post "/forms/library-staff-devices", params: form_params

#       #All 4 boxes must be checked to get to confirmation page
#       assert_redirected_to "/forms/library-staff-devices/all_check"
#     end
#   end

#   def test_required_all_boxes_checked
#     with_login(:ucb_lib_staff) do
#       get new_libstaff_edevices_loan_form_path
#       assert_select "#libstaff_edevices_loan_form_borrow_check[required=required]"
#       assert_select "#libstaff_edevices_loan_form_lending_check[required=required]"
#       assert_select "#libstaff_edevices_loan_form_fines_check[required=required]"
#       assert_select "#libstaff_edevices_loan_form_edevices_check[required=required]"
#     end
#   end
end

