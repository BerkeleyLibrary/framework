require 'forms_helper'

describe 'TIND Download Request Form', type: :request do
  attr_reader :patron_id
  attr_reader :patron
  attr_reader :user

  context 'specs for non-staff user' do
    it 'page redirects' do
      get tind_download_path
      expect(response.status).to eq 302
    end
  end

  context 'specs for staff user' do
    before(:each) do
      @patron_id = Patron::Type.sample_id_for(Patron::Type::STAFF)
      @user = login_as_patron(patron_id)
      @patron = Patron::Record.find(patron_id)

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
