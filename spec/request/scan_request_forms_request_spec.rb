require 'calnet_helper'

describe :scan_request_forms, type: :request do
  describe 'with a valid user' do
    attr_reader :patron_id
    attr_reader :patron
    attr_reader :user

    before(:each) do
      @patron_id = Patron::Type.sample_id_for(Patron::Type::FACULTY)
      @user = login_as(patron_id)

      @patron = Patron::Record.find(patron_id)
    end

    after(:each) do
      logout!
    end

    it 'handles patron API errors' do
      expect(Patron::Record).to receive(:find).with(patron_id).and_raise(Error::PatronApiError)
      get new_scan_request_form_path
      expect(response).to have_http_status(:service_unavailable)
    end

    it 'respects patron blocks' do
      expect(Patron::Record).to receive(:find).with(patron_id).and_return(patron)
      expect(patron).to receive(:blocks).and_return('block all the things')
      get new_scan_request_form_path
      expect(response).to have_http_status(:forbidden)
    end

    it 'rejects a submission with missing fields' do
      # this shouldn't be possible in the UI, but let's be sure
      post('/forms/altmedia', params: {
             scan_request_form: {}
           })
      expect(response).to redirect_to(new_scan_request_form_path)
    end

    it 'redirects from :index to :new' do
      get scan_request_forms_path
      expect(response).to redirect_to(new_scan_request_form_path)
    end

    it 'redirects from :show to :new' do
      some_meaningless_id = Time.now.to_i.to_s
      get scan_request_form_path(some_meaningless_id)
      expect(response).to redirect_to(new_scan_request_form_path)
    end
  end
end
