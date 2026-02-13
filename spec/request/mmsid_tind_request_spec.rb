require 'rails_helper'
require 'calnet_helper'
require 'support/tind_marc_contexts'

RSpec.describe MmsidTindController, type: :request do
  describe 'with a unauthorized user' do
    before do
      logout!
    end

    context 'new/create' do
      it 'GET requires login' do
        get mmsid_tind_path
        expect(response).to have_http_status :unauthorized
      end

      it 'POST requires login' do
        args = {}
        post mmsid_tind_path, params: args
        expect(response).to have_http_status :unauthorized
      end
    end
  end

  describe 'with an authorized user' do

    before do
      login_as_patron(Alma::ALMA_ADMIN_ID)
    end

    after do
      logout!
    end

    describe 'provide correct parameters' do
      include_context 'setup_with_args', :directory_batch_path
      context 'GET #create' do
        it 'response' do
          get mmsid_tind_path
          expect(response).to have_http_status :ok
          expect(response.body).to include('MMSID and Tind Information Tool')
        end
      end

      context 'POST #create' do
        it 'submitted without error' do
          post mmsid_tind_path, params: args
          render_template(:result)
          expect(response).to have_http_status :ok
        end
      end
    end

    describe 'provide incorrect parameters - not batch path' do
      include_context 'setup_with_args', :no_batch_path
      it 'submit but not succeed, re-direct to new tool page' do
        post mmsid_tind_path, params: args
        render_template(:new)
        expect(response).to have_http_status :found
      end
    end

    describe 'directory from parameter has no digital data' do
      include_context 'setup_with_args', :no_digital_data
      it 'submit but not succeed, re-direct to new tool page' do
        post mmsid_tind_path, params: args
        render_template(:new)
        expect(response).to have_http_status :found
      end
    end
  end

end
