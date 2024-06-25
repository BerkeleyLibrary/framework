require 'rails_helper'
require 'calnet_helper'
RSpec.describe DoemoffPatronEmailFormsController, type: :request do
  context 'specs for unauthorized user' do
    before do
      logout!
    end

    context 'index' do
      it 'GET redirects to login' do
        get(form_path = security_incident_report_forms_path)
        login_with_callback_url = "#{login_path}?#{URI.encode_www_form(url: form_path)}"
        expect(response).to redirect_to(login_with_callback_url)
      end
    end
  end

  context 'specs for logged in user' do
    before do
      mock_login(CalnetHelper::STACK_REQUEST_ADMIN_UID)
      @required_params = {
        patron_email: 'test@berkeley.edu',
        patron_message: 'test message',
        sender: 'libtest@berkeley.edu',
        recipient_email: 'main-circ@berkeley.edu'
      }

      @unknown_param = @required_params.merge(should_fail: 'this param does not exist')
    end

    it 'doemoff patron email index page redirects to form' do
      get doemoff_patron_email_forms_path
      expect(response).to redirect_to(action: :new)
    end

    it 'rejects a submission with missing fields' do
      post('/forms/doemoff-patron-email', params: { doemoff_patron_email_form: {} })
      expect(response).to redirect_to(new_doemoff_patron_email_form_path)
    end

    it 'accepts a submission with required params and redirects to success page' do
      params = { doemoff_patron_email_form: @required_params }
      post('/forms/doemoff-patron-email', params:)
      expect(response.status).to eq 200
      expect(response.body).to match(/Your message has been sent/)
    end

    it 'fails if an invalid param is sent' do
      params = { doemoff_patron_email_form: @unknown_param }
      expect { post('/forms/doemoff-patron-email', params:) }.to raise_error ActiveModel::UnknownAttributeError
    end

  end
end
