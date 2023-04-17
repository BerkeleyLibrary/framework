require 'calnet_helper'

RSpec.describe BibliographicsController, type: :request do
  context 'specs for unauthenticated user' do
    before do
      logout!
    end

    context 'new/create' do
      it 'GET redirects to login' do
        get(form_path = bibliographics_path)
        login_with_callback_url = "#{login_path}?#{URI.encode_www_form(url: form_path)}"
        expect(response).to redirect_to(login_with_callback_url)
      end

      it 'POST redirects to login' do
        post bibliographics_path, params: { upload_file: nil }
        login_with_callback_url = "#{login_path}?#{URI.encode_www_form(url: bibliographics_path)}"
        expect(response).to redirect_to(login_with_callback_url)
      end
    end

    context 'index' do
      it 'GET redirects to login' do
        get(form_path = bibliographics_index_path)
        login_with_callback_url = "#{login_path}?#{URI.encode_www_form(url: form_path)}"
        expect(response).to redirect_to(login_with_callback_url)
      end
    end
  end

  context 'specs for staff users' do
    before do
      patron_id = Alma::Type.sample_id_for(Alma::Type::STAFF)
      login_as_patron(patron_id)
    end

    after do
      logout!
    end

    context 'GET #create' do
      it 'response' do
        get bibliographics_path
        expect(response.status).to eq 200
        expect(response.body).to include('Please choose a &#39;.txt&#39; file')
      end
    end

    context 'POST #create' do
      it 'created without error' do
        upload_file = Rack::Test::UploadedFile.new(Rails.root.join('spec', 'data', 'bibliographic', 'upload_file.txt'), 'plain/text')
        post bibliographics_path, params: { upload_file: }
        expect(response).to redirect_to(action: :index)
      end

      it 'created with error' do
        upload_file = Rack::Test::UploadedFile.new(Rails.root.join('spec', 'data', 'bibliographic', 'upload_file.csv'), 'plain/text')
        post bibliographics_path, params: { upload_file: }
        expect(flash[:danger]).to eq("The file must be in the '.txt' format,The file is empty")
        expect(response).to redirect_to(bibliographics_path)
      end
    end

  end
end
