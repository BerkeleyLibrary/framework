require 'forms_helper'

describe :service_article_request_forms, type: :request do

  describe 'with a "book scan eligible" note' do
    before(:each) do
      eligible_notes = ['20190101 library book scan eligible [litscript]']
      allow_any_instance_of(Patron::Record).to receive(:notes).and_return(eligible_notes)
    end

    it_behaves_like(
      'an authenticated form',
      form_class: ServiceArticleRequestForm,
      allowed_patron_types: Patron::Type.all,
      submit_path: '/forms/altmedia-articles',
      success_path: '/forms/altmedia-articles/confirmed',
      valid_form_params: {
        service_article_request_form: {
          patron_email: 'ethomas@berkeley.edu',
          display_name: 'Elissa Thomas',
          pub_title: 'A Test Publication',
          article_title: 'Exciting scholarly article title',
          vol: '3',
          citation: 'Davis, K. Exciting scholarly article title. A Test Publication: 3'
        }
      }
    )
  end

  it 'requires a "book scan eligible" note' do
    not_eligible_notes = ['I might be eligible for some stuff but not this']
    allow_any_instance_of(Patron::Record).to receive(:notes).and_return(not_eligible_notes)
    all_patron_ids.each do |patron_id|
      with_login(patron_id) do
        get new_service_article_request_form_path
        expect(response).to have_http_status(:forbidden)
      end
    end
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
