require 'rails_helper'
require 'calnet_helper'
RSpec.describe DepartmentalCardFormsController, type: :request do
  context 'specs for unauthorized user' do
    before do
      logout!
    end

    context 'new' do
      it 'GET redirects to login' do
        get(form_path = new_departmental_card_form_path)
        login_with_callback_url = "#{login_path}?#{URI.encode_www_form(url: form_path)}"
        expect(response).to redirect_to(login_with_callback_url)
      end
    end
  end

  describe 'authenticated user' do
    before do
      @current_user = login_as_patron(Alma::UNIVERSITY_STAFF_ID)
      @current_user.email = 'notreal@nowhere.com'

      allow_any_instance_of(DepartmentalCardFormsController).to receive(:current_user).and_return(@current_user)
    end

    context 'new' do
      it 'GET opens the form' do
        get(new_departmental_card_form_path)
        expect(response.body).to include('<h1>Request a Departmental Card</h1>')
      end
    end

    context 'index' do
      it 'GET redirects to new' do
        get(departmental_card_forms_path)
        expect(response).to redirect_to(new_departmental_card_form_path)
      end
    end

    context 'create' do
      it 'rejects a form with missing fields and redirects back to form' do
        post(departmental_card_forms_path, params: {
               name: 'Just Steve',
               address: 'whatever'
             })

        expect(response.status).to eq 302
        expect(response).to redirect_to(action: :new, name: 'Just Steve', address: 'whatever')
      end

      it 'accepts a form with all required fields' do
        # name address email phone supervisor_name supervisor_email barcode reason
        post(departmental_card_forms_path, params: {
               name: 'Just Steve',
               address: 'whatever',
               email: 'juststeve@berkeley.edu',
               phone: '9255551234',
               supervisor_name: 'Awesome Supervisor',
               supervisor_email: 'awesomeness@berkeley.edu',
               barcode: 'KA05',
               reason: 'Test this out!'
             })

        expect(response.status).to eq 200
        expect(response.body).to include('The Request a Departmental Card Form has been successfully submitted.')
      end
    end

  end
end
