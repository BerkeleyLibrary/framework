require 'rails_helper'
require 'calnet_helper'
RSpec.describe TindMarcBatchTestController, type: :request do
  context 'specs for unauthorized user' do
    before do
      logout!
    end

    context 'index' do
      it 'GET redirects to login' do
        get(form_path = tind_marc_batch_path)
        login_with_callback_url = "#{login_path}?#{URI.encode_www_form(url: form_path)}"
        expect(response).to redirect_to(login_with_callback_url)
      end
    end
  end

  describe 'authenticated user' do
    before do
      # login_as_patron(Alma::ALMA_ADMIN_ID)
      @current_user = login_as_patron(Alma::ALMA_ADMIN_ID)
      @current_user.email = 'notreal@nowhere.com'

      # And pass @user to the controller as the current_user:
      allow_any_instance_of(TindMarcBatchController).to receive(:current_user).and_return(@current_user)
      puts @current_user.inspect
    end

    context 'index' do
      it 'GET brings up batch form if user is authenticated' do
        get(tind_marc_batch_path)
        expect(@current_user.alma_admin?).to be(true)
      end
    end
  end
end
