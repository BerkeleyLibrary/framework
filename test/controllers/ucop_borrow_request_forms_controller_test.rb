require 'test_helper'

class UcopBorrowRequestFormsControllerTest < ActionDispatch::IntegrationTest
  def test_index_redirects_to_new_with_params
    get ucop_borrow_request_forms_path(foo: :bar)
    assert_redirected_to "/forms/ucop-borrowing-card/new?foo=bar"
  end

  def test_new_page_renders_with_correct_headline
    get new_ucop_borrow_request_form_path
    assert_response :ok
    assert_select "h1", 'Access to UC Berkeley Library Resources for Select UCOP Staff'
  end

  def test_questions_link_goes_to_privdesk_email
    get new_ucop_borrow_request_form_path
    assert_select('.page-footer .support-email[href=?]', 'mailto:privdesk@library.berkeley.edu')
  end
end
