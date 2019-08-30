require 'rails_helper'

describe :ucop_borrow_request_forms, type: :request do
  it 'redirects from :index to :new' do
    get ucop_borrow_request_forms_path
    expect(response).to redirect_to(new_ucop_borrow_request_form_path)
  end

  it 'rejects a submission with missing fields' do
    post('/forms/ucop-borrowing-card', params: {
           ucop_borrow_request_form: {}
         })
    expect(response).to redirect_to(new_ucop_borrow_request_form_path)
  end

  it 'accepts a submission' do
    post('/forms/ucop-borrowing-card', params: {
           ucop_borrow_request_form: {
             department_head_email: 'jrdoe@ucop.test',
             department_head_name: 'Jane R. Doe',
             department_name: 'Office of the Vice Provost for Test',
             employee_email: 'rjdoe@ucop.test',
             employee_id: '5551212',
             employee_name: 'Rachel J. Doe',
             employee_personal_email: 'rjdoe@example.test',
             employee_phone: '555-1212',
             employee_preferred_name: 'RJ Doe',
             employee_address: '123 Sesame St, Oakland CA 94607'
           }
         })
    expect(response).to redirect_to(%r{/forms/ucop-borrowing-card/new})
    get response.header['Location']
    expect(response.body).to match(/Request successfully submitted/)
  end

  it 'rejects a submission with a captcha failure' do
    expect_any_instance_of(Recaptcha::Verify).to receive(:verify_recaptcha).and_return(false)

    post('/forms/ucop-borrowing-card', params: {
           ucop_borrow_request_form: {
             department_head_email: 'jrdoe@ucop.test',
             department_head_name: 'Jane R. Doe',
             department_name: 'Office of the Vice Provost for Test',
             employee_email: 'rjdoe@ucop.test',
             employee_id: '5551212',
             employee_name: 'Rachel J. Doe',
             employee_personal_email: 'rjdoe@example.test',
             employee_phone: '555-1212',
             employee_preferred_name: 'RJ Doe',
             employee_address: '123 Sesame St, Oakland CA 94607'
           }
         })
    expect(response).to redirect_to(%r{/forms/ucop-borrowing-card/new})
    get response.header['Location']
    expect(response.body).to match('RECaptcha Error')
  end

  it 'rejects a submission with a captcha verification error' do
    expect_any_instance_of(Recaptcha::Verify).to receive(:verify_recaptcha).and_raise(Recaptcha::RecaptchaError)

    post('/forms/ucop-borrowing-card', params: {
           ucop_borrow_request_form: {
             department_head_email: 'jrdoe@ucop.test',
             department_head_name: 'Jane R. Doe',
             department_name: 'Office of the Vice Provost for Test',
             employee_email: 'rjdoe@ucop.test',
             employee_id: '5551212',
             employee_name: 'Rachel J. Doe',
             employee_personal_email: 'rjdoe@example.test',
             employee_phone: '555-1212',
             employee_preferred_name: 'RJ Doe',
             employee_address: '123 Sesame St, Oakland CA 94607'
           }
         })
    expect(response).to redirect_to(%r{/forms/ucop-borrowing-card/new})
    get response.header['Location']
    expect(response.body).to match('RECaptcha Error')
  end
end
