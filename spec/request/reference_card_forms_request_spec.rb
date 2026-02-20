require 'forms_helper'

describe 'Reference Card Form', type: :request do
  include ActiveJob::TestHelper
  after { clear_enqueued_jobs }

  attr_reader :patron_id
  attr_reader :patron
  attr_reader :user

  context 'specs without admin privledges' do
    before do
      login_as_patron(Alma::NON_FRAMEWORK_ADMIN_ID)
      allow_any_instance_of(User).to receive(:role?).with(Role.stackpass_admin).and_return(false)
    end

    it 'reference card index page redirects to form' do
      get reference_card_forms_path
      expect(response).to have_http_status :found
      expect(response).to redirect_to(action: :new)
    end

    it 'requires login if user is not a stack pass admin' do
      form = ReferenceCardForm.create(id: 1, email: 'openreq@test.com', name: 'John Doe',
                                      pass_date: Date.current, pass_date_end: Date.current + 1)
      get reference_card_form_path(id: form.id)
      expect(response).to have_http_status :forbidden
    end

    it 'rejects a submission with a captcha verification error' do
      expect_any_instance_of(Recaptcha::Verify).to receive(:verify_recaptcha).and_raise(Recaptcha::RecaptchaError)

      params = {
        reference_card_form: {
          email: 'jrdoe@affiliate.test',
          name: 'Jane R. Doe',
          affiliation: 'nowhere',
          research_desc: 'research goes here....',
          pass_date: '04/13/1996',
          pass_date_end: '04/15/1996',
          local_id: '123456789'
        }
      }

      post('/forms/reference-card', params:)
      expect(response).to redirect_to(action: :new, params:)

      get response.header['Location']
      expect(response.body).to match('RECaptcha Error')
    end

    it 'accepts a submission with a valid date and enqueues email' do
      params = {
        reference_card_form: {
          email: 'jrdoe@affiliate.test',
          name: 'Jane R. Doe',
          affiliation: 'nowhere',
          research_desc: 'research goes here....',
          pass_date: Date.current,
          pass_date_end: Date.current,
          local_id: '123456789'
        }
      }

      expect { post('/forms/reference-card', params:) }.to have_enqueued_job(ActionMailer::MailDeliveryJob)

      expect(response).to have_http_status :created
    end

    it 'rejects a submission with a requested end date before the start date' do
      params = {
        reference_card_form: {
          email: 'jrdupree@affiliate.test',
          name: 'Jane R. Duprie',
          affiliation: 'nowhere',
          research_desc: 'research goes here....',
          pass_date: Date.current,
          pass_date_end: Date.current - 5.days,
          local_id: '123456789'
        }
      }

      post('/forms/reference-card', params:)
      expect(response).to have_http_status :found

      follow_redirect!
      expect(response.body).to include('Requested access end date must not precede access start date')
    end
  end

  context 'specs with admin privledges' do
    before do
      admin_user = User.new(display_name: 'Test Admin', uid: '1707532', affiliations: ['EMPLOYEE-TYPE-ACADEMIC'])
      allow_any_instance_of(ReferenceCardFormsController).to receive(:current_user).and_return(admin_user)
      allow_any_instance_of(StackRequestsController).to receive(:current_user).and_return(admin_user)
    end

    it 'renders process form for unprocessed request' do
      form = ReferenceCardForm.create(id: 1, email: 'openreq@test.com', name: 'John Testy',
                                      pass_date: Date.current, pass_date_end: Date.current + 1,
                                      research_desc: 'This is research', affiliation: 'Affiliation 1',
                                      local_id: '8675309')

      get "/forms/reference-card/#{form.id}"
      expect(response.body).to include('<h3>This Reference Card request needs to be processed.</h3>')
    end

    it 'renders processed page for processed request' do
      form = ReferenceCardForm.create(
        email: 'closedreq@test.com', name: 'Jane Testy',
        pass_date: Date.current, pass_date_end: Date.current + 1,
        research_desc: 'This is research', affiliation: 'Affiliation 1',
        local_id: '8675309',
        approvedeny: true, processed_by: 'Test Admin'
      )

      get "/forms/reference-card/#{form.id}"
      expect(response.body).to include('<h2>This request has been processed</h2>')
    end

    it 'renders 404 if request does not exist' do
      get(path = '/forms/reference-card/does-not-exist')
      expect(response).to have_http_status :not_found
      expect(response.body).to include(path)
    end

    it 'allows an admin to deny a request and enqueues denial email' do
      form = ReferenceCardForm.create(email: 'openreq@test.com', name: 'John Doe',
                                      affiliation: 'Red Bull',
                                      pass_date: Date.current,
                                      pass_date_end: Date.current + 1,
                                      local_id: '8675309')

      expect do
        patch("/forms/reference-card/#{form.id}", params: {
                'stack_pass_[approve_deny]' => false,
                'processed_by' => 'ADMIN USER',
                'denial_reason' => 'Item listed at another library'
              })
      end.to have_enqueued_job(ActionMailer::MailDeliveryJob)

      expect(response).to redirect_to(action: :show, id: form.id)

      get(response.headers['Location'])
      expect(response.body).to include('Item listed at another library')
      expect(response.body).to include('This request has been processed')
    end

    it 'enqueues approval email when admin approves request' do
      form = ReferenceCardForm.create(email: 'openreq@test.com', name: 'John Doe',
                                      affiliation: 'Test',
                                      pass_date: Date.current,
                                      pass_date_end: Date.current + 1,
                                      local_id: '8675309')

      expect do
        patch("/forms/reference-card/#{form.id}", params: {
                'stack_pass_[approve_deny]' => true,
                'processed_by' => 'ADMIN USER'
              })
      end.to have_enqueued_job(ActionMailer::MailDeliveryJob)
    end
  end
end
