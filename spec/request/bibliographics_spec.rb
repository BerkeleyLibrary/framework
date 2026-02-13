require 'calnet_helper'

RSpec.describe BibliographicsController, type: :request do
  context 'specs for unauthorized user' do
    before do
      logout!
    end

    context 'new/create' do
      it 'GET requires login' do
        get bibliographics_path
        expect(response).to have_http_status :unauthorized
      end

      it 'POST requires login' do
        post bibliographics_path, params: { upload_file: nil }
        expect(response).to have_http_status :unauthorized
      end
    end

    # context 'index' do
    #   it 'GET requires login' do
    #     get bibliographics_index_path
    #     expect(response).to have_http_status :unauthorized
    #   end
    # end

    context 'response' do
      it 'GET requires login' do
        get bibliographics_response_path
        expect(response).to have_http_status :unauthorized
      end
    end

  end

  context 'specs for authorized user' do
    after do
      logout!
    end

    shared_examples 'an authorized user' do
      context 'GET #create' do
        it 'response' do
          get bibliographics_path
          expect(response).to have_http_status :ok
          expect(response.body).to include('Please choose a &#39;.txt&#39; file')
        end
      end

      context 'POST #create' do
        it 'created without error' do
          upload_file = Rack::Test::UploadedFile.new(Rails.root.join('spec', 'data', 'bibliographic', 'upload_file.txt'), 'plain/text')
          post bibliographics_path, params: { upload_file: }
          expect(response).to redirect_to(action: :response)
        end

        it 'created with error' do
          upload_file = Rack::Test::UploadedFile.new(Rails.root.join('spec', 'data', 'bibliographic', 'upload_file.csv'), 'plain/text')
          post bibliographics_path, params: { upload_file: }
          expect(flash[:danger]).to eq("The file must be in the '.txt' format,The file is empty")
          expect(response).to redirect_to(bibliographics_path)
        end
      end
    end

    context 'specs for Framework admins' do
      before do
        login_as_patron(Alma::FRAMEWORK_ADMIN_ID)
      end

      it_behaves_like 'an authorized user'
    end

    context 'specs for Alma admins' do
      before do
        login_as_patron(Alma::ALMA_ADMIN_ID)
      end

      it_behaves_like 'an authorized user'
    end
  end

end
