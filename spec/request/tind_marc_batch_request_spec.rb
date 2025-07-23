require 'rails_helper'
require 'calnet_helper'
require 'support/tind_marc_contexts'

RSpec.describe TindMarcBatchController, type: :request do

  describe 'with a unauthorized user' do
    before do
      logout!
    end

    context 'new/create' do
      it 'GET redirects to login' do
        get(form_path = tind_marc_batch_path)
        login_with_callback_url = "#{login_path}?#{URI.encode_www_form(url: form_path)}"
        expect(response).to redirect_to(login_with_callback_url)
      end

      it 'POST redirects to login' do
        args = {}
        post tind_marc_batch_path, params: args
        login_with_callback_url = "#{login_path}?#{URI.encode_www_form(url: tind_marc_batch_path)}"
        expect(response).to redirect_to(login_with_callback_url)
      end
    end
  end

  describe 'with an authorized user' do

    before do
      login_as_patron(Alma::ALMA_ADMIN_ID)

      # And pass @user to the controller as the current_user:
      # allow_any_instance_of(TindMarcBatchController).to receive(:current_user).and_return(@current_user)
    end

    after do
      logout!
    end

    describe 'provide correct parameters' do
      include_context 'setup_with_args', :directory_batch_path
      context 'GET #create' do
        it 'response' do
          get tind_marc_batch_path
          expect(response).to have_http_status :ok
          expect(response.body).to include('902_n (your initials)')
        end
      end

      context 'POST #create' do
        it 'submitted without error' do
          post tind_marc_batch_path, params: args
          render_template(:result)
          expect(response).to have_http_status :ok
        end
      end
    end

    describe 'provide incorrect parameters - not batch path' do
      include_context 'setup_with_args', :no_batch_path
      it 'submit but not succeed, re-direct to new tool page' do
        post tind_marc_batch_path, params: args
        render_template(:new)
        expect(response).to have_http_status :found
      end
    end

    describe 'directory from parameter has no digital data' do
      include_context 'setup_with_args', :no_digital_data
      it 'submit but not succeed, re-direct to new tool page' do
        post tind_marc_batch_path, params: args
        render_template(:new)
        expect(response).to have_http_status :found
      end
    end
  end
end
