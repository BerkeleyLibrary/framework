require 'calnet_helper'

describe :service_article_request_forms, type: :request do
  it 'redirects to login' do
    expected_location = login_path(url: new_service_article_request_form_path)
    get new_service_article_request_form_path
    expect(response).to redirect_to(expected_location)
  end

  it 'requires a "book scan eligible" note' do
    eligible_ids = []
    ineligible_ids = []
    all_patron_ids.each do |patron_id|
      with_login(patron_id) do |user|
        patron = user.primary_patron_record
        eligible = patron.notes.any? { |n| n =~ /book scan eligible/ }
        expected_status = eligible ? :ok : :forbidden
        get new_service_article_request_form_path
        expect(response).to have_http_status(expected_status)

        (eligible ? eligible_ids : ineligible_ids) << patron_id
      end
    end

    # just to make sure we've tested both cases
    expect(eligible_ids).not_to be_empty
    expect(ineligible_ids).not_to be_empty
  end

  describe 'with a valid user' do
    attr_reader :patron_id
    attr_reader :patron
    attr_reader :user

    before(:each) do
      @patron_id = Patron::Type.sample_id_for(Patron::Type::POST_DOC)
      @user = login_as(patron_id)

      @patron = Patron::Record.find(patron_id)
      eligible = patron.notes.any? { |n| n =~ /book scan eligible/ }
      expect(eligible).to eq(true) # just to be sure
    end

    after(:each) do
      logout!
    end

    it 'handles patron API errors' do
      expect(Patron::Record).to receive(:find).with(patron_id).and_raise(Error::PatronApiError)
      get new_service_article_request_form_path
      expect(response).to have_http_status(:service_unavailable)
    end

    it 'respects patron blocks' do
      expect(Patron::Record).to receive(:find).with(patron_id).and_return(patron)
      expect(patron).to receive(:blocks).and_return('block all the things')
      get new_service_article_request_form_path
      expect(response).to have_http_status(:forbidden)
    end

    it 'rejects a submission with missing fields' do
      post('/forms/altmedia-articles', params: {
             service_article_request_form: {}
           })
      expect(response).to redirect_to(new_service_article_request_form_path)
    end

    it 'accepts a submission' do
      post('/forms/altmedia-articles', params: {
             service_article_request_form: {
               patron_email: 'ethomas@berkeley.edu',
               display_name: 'Elissa Thomas',
               pub_title: 'A Test Publication',
               article_title: 'Exciting scholarly article title',
               vol: '3',
               citation: 'Davis, K. Exciting scholarly article title. A Test Publication: 3'
             }
           })
      assert_redirected_to '/forms/altmedia-articles/confirmed'
    end

    it 'redirects from :index to :new' do
      get service_article_request_forms_path
      expect(response).to redirect_to(new_service_article_request_form_path)
    end

    it 'redirects from :show to :new' do
      some_meaningless_id = Time.now.to_i.to_s
      get service_article_request_form_path(some_meaningless_id)
      expect(response).to redirect_to(new_service_article_request_form_path)
    end
  end
end
