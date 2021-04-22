require 'forms_helper'

describe 'TIND Download Request Form', type: :request do
  attr_reader :patron_id
  attr_reader :patron
  attr_reader :user

  context 'specs for unauthenticated user' do
    before(:each) do
      logout! # just to be sure
    end

    it 'page redirects' do
      get(form_path = tind_download_path)
      expect(response).to redirect_to("#{login_path}?#{URI.encode_www_form(url: form_path)}")
    end
  end

  context 'specs for non-staff user' do
    around(:each) do |example|
      patron_id = Patron::Type.sample_id_for(Patron::Type::FACULTY)
      with_patron_login(patron_id) { example.run }
    end

    it 'returns 403' do
      get tind_download_path
      expect(response.status).to eq(403)
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
        body: File.new('spec/data/tindcollections.json')
      )
    end

    it 'form opens' do
      get tind_download_path
      expect(response.status).to eq 200
      expect(response.body).to include('<h1>TIND Metadata Download</h1>')
    end
  end
end
