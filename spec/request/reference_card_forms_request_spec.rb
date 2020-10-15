require 'forms_helper'

describe 'Reference Card Form', type: :request do
  attr_reader :patron_id
  attr_reader :patron
  attr_reader :user

  context 'specs without admin privledges' do
    before(:all) do
      # Clear the way:
      StackRequest.delete_all

      # Create some requests:
      ReferenceCardForm.create(id: 1, email: 'openreq@test.com', name: 'John Doe',
                               pass_date: Date.today, pass_date_end: Date.today + 1)
      ReferenceCardForm.create(id: 2, email: 'closedreq@test.com', name: 'Jane Doe',
                               pass_date: Date.today, pass_date_end: Date.today + 1)
    end

    it 'reference card index page redirects to form' do
      get reference_card_forms_path
      expect(response.status).to eq 302
    end

    it 'renders forbidden page if user is not a stack pass admin' do
      get reference_card_form_path(id: 1)
      expect(response.body).to include('redirected')
    end

    it 'rejects a submission with a captcha verification error' do
      expect_any_instance_of(Recaptcha::Verify).to receive(:verify_recaptcha).and_raise(Recaptcha::RecaptchaError)

      post('/forms/reference-card', params: {
             reference_card_form: {
               email: 'jrdoe@affiliate.test',
               name: 'Jane R. Doe',
               affiliation: 'nowhere',
               research_desc: 'research goes here....',
               pass_date: '04/13/1996',
               pass_date_end: '04/15/1996',
               local_id: '123456789'
             }
           })
      expect(response).to redirect_to(%r{/forms/reference-card/new})
      get response.header['Location']
      expect(response.body).to match('RECaptcha Error')
    end

  end

  context 'specs with admin privledges' do
    before(:all) do
      # Clear the way:
      StackRequest.delete_all

      # Create some requests:
      ReferenceCardForm.create(id: 1, email: 'openreq@test.com', name: 'John Doe',
                               pass_date: Date.today, pass_date_end: Date.today + 1,
                               research_desc: 'This is research', affiliation: 'Affiliation 1',
                               local_id: '8675309')
      ReferenceCardForm.create(id: 2, email: 'closedreq@test.com', name: 'Jane Doe',
                               pass_date: Date.today, pass_date_end: Date.today + 1,
                               research_desc: 'This is research', affiliation: 'Affiliation 1',
                               local_id: '8675309',
                               approvedeny: true, processed_by: 'Test Admin')
    end

    before(:each) do |_test|
      admin_user = User.new(display_name: 'Test Admin', uid: '1707532', affiliations: ['EMPLOYEE-TYPE-ACADEMIC'])
      allow_any_instance_of(ReferenceCardFormsController).to receive(:current_user).and_return(admin_user)
      allow_any_instance_of(StackRequestsController).to receive(:current_user).and_return(admin_user)
    end

    it 'renders process form for unprocessed request' do
      get '/forms/reference-card/1'
      expect(response.body).to include('<h3>This Reference Card request needs to be processed.</h3>')
    end

    it 'renders processed page for processed request' do
      get '/forms/reference-card/2'
      expect(response.body).to include('<h2>This request has been processed</h2>')
    end

    it 'renders 404 if request does not exist' do
      get '/forms/reference-card/5000'
      expect(response.body).to include('<h1>404 - Page not found</h1>')
    end

  end

end
