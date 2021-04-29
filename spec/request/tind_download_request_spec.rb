require 'forms_helper'

describe TindDownloadController, type: :request do
  let(:collection_name) { 'Abraham Lincoln Papers' }

  attr_reader :patron_id
  attr_reader :patron
  attr_reader :user

  context 'specs for unauthenticated user' do
    before(:each) do
      logout! # just to be sure
    end

    describe 'form' do
      it 'redirects to login' do
        get(form_path = tind_download_path)
        login_with_callback_url = "#{login_path}?#{URI.encode_www_form(url: form_path)}"
        expect(response).to redirect_to(login_with_callback_url)
      end
    end

    describe 'find_collection' do
      it 'redirects to login' do
        get tind_download_find_collection_path
        login_with_callback_url = "#{login_path}?#{URI.encode_www_form(url: tind_download_find_collection_path)}"
        expect(response).to redirect_to(login_with_callback_url)
      end
    end

    describe 'download' do
      it 'POST redirects to login' do
        post tind_download_download_path, params: { collection_name: collection_name, export_format: 'csv' }
        login_with_callback_url = "#{login_path}?#{URI.encode_www_form(url: tind_download_download_path)}"
        expect(response).to redirect_to(login_with_callback_url)
      end

      it 'GET redirects to login' do
        params = { collection_name: collection_name, export_format: 'csv' }
        get tind_download_download_path, params: params

        callback_url = "#{tind_download_download_path}?#{URI.encode_www_form(params)}"
        login_with_callback_url = "#{login_path}?#{URI.encode_www_form(url: callback_url)}"
        expect(response).to redirect_to(login_with_callback_url)
      end
    end
  end

  context 'specs for non-staff user' do
    around(:each) do |example|
      patron_id = Patron::Type.sample_id_for(Patron::Type::FACULTY)
      with_patron_login(patron_id) { example.run }
    end

    describe 'form' do
      it 'returns 403' do
        get tind_download_path
        expect(response.status).to eq(403)
      end
    end

    describe 'find_collection' do
      it 'returns 403' do
        get tind_download_find_collection_path
        expect(response.status).to eq(403)
      end
    end

    describe 'download' do
      it 'returns 403 for a POST' do
        post tind_download_download_path, params: { collection_name: collection_name, export_format: 'csv' }
        expect(response.status).to eq(403)
      end

      it 'returns 403 for a GET' do
        get tind_download_download_path, params: { collection_name: collection_name, export_format: 'csv' }
        expect(response.status).to eq(403)
      end
    end
  end

  context 'specs for staff user' do
    around(:each) do |example|
      patron_id = Patron::Type.sample_id_for(Patron::Type::STAFF)
      with_patron_login(patron_id) { example.run }
    end

    before(:each) do
      stub_request(:get, 'https://digicoll.lib.berkeley.edu/api/v1/collections?depth=100').to_return(
        status: 200,
        body: File.new('spec/data/tind_download/collections.json')
      )
    end

    describe 'form' do
      it 'is displayed' do
        get tind_download_path
        expect(response.status).to eq 200
        expect(response.body).to include('TIND Metadata Download')
      end
    end

    describe 'find_collection' do
      it 'requires a collection' do
        expect { get tind_download_find_collection_path }.to raise_error(ActionController::ParameterMissing)
      end

      it 'returns the matching collection name list' do
        get tind_download_find_collection_path, params: { collection_name: 'Abraham' }
        expect(response.status).to eq 200
        result = JSON.parse(response.body)
        expect(result).to be_a(Array)
        expect(result).to contain_exactly('Abraham Lincoln Papers', 'Veterans of the Abraham Lincoln Brigade')
      end

      it 'returns an empty list for an unmatched name' do
        get tind_download_find_collection_path, params: { collection_name: 'axolotl' }
        expect(response.status).to eq 200
        result = JSON.parse(response.body)
        expect(result).to be_a(Array)
        expect(result).to be_empty
      end
    end

    describe 'download' do
      let(:expected_body) { File.read('spec/data/tind_download/tind-abraham-lincoln.csv') }

      before(:each) do
        search_url = 'https://digicoll.lib.berkeley.edu/api/v1/search'
        search_params = { c: collection_name, format: 'xml' }
        search_params_with_search_id = search_params.merge(search_id: 'DnF1ZXJ5VGhlbkZldGNoBQAAAAABsY')
        result_1 = File.read('spec/data/tind_download/tind-abraham-lincoln-1.xml')
        result_2 = File.read('spec/data/tind_download/tind-abraham-lincoln-2.xml')
        stub_request(:get, search_url).with(query: search_params).to_return(status: 200, body: result_1)
        stub_request(:get, search_url).with(query: search_params_with_search_id).to_return(status: 200, body: result_2)
      end

      it 'supports POST' do
        post tind_download_download_path, params: { collection_name: collection_name, export_format: 'csv' }
        expect(response.status).to eq(200)
        expect(response.body).to eq(expected_body)
      end

      it 'supports GET' do
        get tind_download_download_path, params: { collection_name: collection_name, export_format: 'csv' }
        expect(response.status).to eq(200)
        expect(response.body).to eq(expected_body)
      end
    end

  end
end
