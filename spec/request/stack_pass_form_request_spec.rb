# require 'forms_helper'
require 'rails_helper'

describe 'Stack Pass Form', type: :request do

  context 'specs without admin privledges' do
    before(:all) do
      # Clear the way:
      StackPassForm.delete_all

      # Create some requests:
      StackPassForm.create(id: 1, email: 'openreq@test.com', name: 'John Doe',
                           phone: '925-555-1234', pass_date: Date.today, main_stack: true)
      StackPassForm.create(id: 2, email: 'closedreq@test.com', name: 'Jane Doe',
                           phone: '925-555-5678', pass_date: Date.today, main_stack: true)
    end

    it 'index page redirects to new forms page' do
      get stack_pass_forms_path
      expect(response).to redirect_to(new_stack_pass_form_path)
    end

    it 'renders forbidden page if user is not a stack pass admin' do
      get stack_pass_form_path(id: 1)
      expect(response.body).to include('<h1>Forbidden</h1>')
    end

    it 'rejects a submission with a captcha verification error' do
      expect_any_instance_of(Recaptcha::Verify).to receive(:verify_recaptcha).and_raise(Recaptcha::RecaptchaError)

      post('/forms/stack-pass', params: {
             stack_pass_form: {
               email: 'jrdoe@affiliate.test',
               name: 'Jane R. Doe',
               phone: '925-555-1212',
               stack_pass_form_main_stack: true,
               pass_date: '04/13/1996',
               local_id: '123456789'
             }
           })
      expect(response).to redirect_to(%r{/forms/stack-pass/new})
      get response.header['Location']
      expect(response.body).to match('RECaptcha Error')
    end

  end

  context 'specs with admin privledges' do
    before(:all) do
      # Clear the way:
      StackPassForm.delete_all

      # Create some requests:
      StackPassForm.create(id: 1, email: 'openreq@test.com', name: 'John Doe',
                           phone: '925-555-1234', pass_date: Date.today, main_stack: true, local_id: '8675309')
      StackPassForm.create(id: 2, email: 'closedreq@test.com', name: 'Jane Doe',
                           phone: '925-555-5678', pass_date: Date.today, main_stack: true, local_id: '8675309',
                           approved: true, approved_by: 'Test Admin')
    end

    before(:each) do |_test|
      admin_user = User.new(display_name: 'Test Admin', uid: '1707532', affiliations: ['EMPLOYEE-TYPE-ACADEMIC'])
      allow_any_instance_of(StackPassFormsController).to receive(:current_user).and_return(admin_user)
    end

    it 'renders process form for unprocessed request' do
      get '/forms/stack-pass/1'
      expect(response.body).to include('<h3>This request needs to be processed.</h3>')
    end

    it 'renders processed page for processed request' do
      get '/forms/stack-pass/2'
      expect(response.body).to include('<h2>This request has been processed</h2>')
    end

    it 'renders 404 if request does not exist' do
      get '/forms/stack-pass/5000'
      expect(response.body).to include('<h1>404 - Page not found</h1>')
    end

  end

end
