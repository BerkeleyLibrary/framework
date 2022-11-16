require 'calnet_helper'

RSpec.shared_examples 'an authenticated form' do |form_class:, allowed_patron_types:, submit_path:, success_path:, valid_form_params:|
  attr_reader :form_name

  let(:alma_api_key) { 'totally-fake-key' }

  forbidden_patron_types = Alma::Type.all.reject { |t| allowed_patron_types.include?(t) }

  missing_field_params = valid_form_params.transform_values { |v| v.is_a?(Hash) ? {} : nil }

  before do
    allow(Rails.application.config).to receive(:alma_api_key).and_return(alma_api_key)
    @form_name = form_class.to_s.underscore
  end

  def new_form_path
    send("new_#{form_name}_path")
  end

  def index_path
    send("#{form_name}s_path")
  end

  def show_path(id)
    send("#{form_name}_path", id)
  end

  it 'redirects to login' do
    expected_location = login_path(url: new_form_path)
    get new_form_path
    expect(response).to redirect_to(expected_location)
  end

  allowed_patron_types.each do |type|
    it "allows #{Alma::Type.name_of(type)}" do
      patron_id = Alma::Type.sample_id_for(type)
      with_patron_login(patron_id) do
        get new_form_path
        expect(response).to have_http_status(:ok)
      end
    end
  end

  forbidden_patron_types.each do |type|
    it "forbids #{Alma::Type.name_of(type)}" do
      patron_id = Alma::Type.sample_id_for(type)
      with_patron_login(patron_id) do
        get new_form_path
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  it 'forbids users without patron records' do
    patron_id = 'does_not_exist'
    with_patron_login(patron_id) do
      get new_form_path
      expect(response).to have_http_status(:forbidden)
      expected_msg = /Your patron record cannot be found/
      expect(response.body).to match(expected_msg)
    end
  end

  describe 'with a valid user' do
    attr_reader :patron_id
    attr_reader :patron
    attr_reader :user

    before do
      @patron_id = Alma::Type.sample_id_for(allowed_patron_types.first)
      @user = login_as_patron(patron_id)

      @patron = Alma::User.find(patron_id)
    end

    after do
      logout!
    end

    it 'handles patron API errors' do
      expect(Alma::User).to receive(:find).with(patron_id).and_raise(Error::PatronApiError)
      get new_form_path
      expect(response).to have_http_status(:service_unavailable)
    end

    it 'respects patron blocks' do
      expect(Alma::User).to receive(:find).with(patron_id).and_return(patron)
      expect(patron).to receive(:blocks).and_return('block all the things')
      get new_form_path
      expect(response).to have_http_status(:forbidden)
    end

    it 'rejects a submission with missing fields' do
      post(submit_path, params: missing_field_params)
      expect(response).to redirect_to(new_form_path)
    end

    it 'accepts a submission' do
      post(submit_path, params: valid_form_params)
      expect(response).to redirect_to(success_path)
    end

    it 'redirects from :index to :new' do
      get index_path
      expect(response).to redirect_to(new_form_path)
    end

    it 'redirects from :show to :new' do
      some_meaningless_id = Time.now.to_i.to_s
      get show_path(some_meaningless_id)
      expect(response).to redirect_to(new_form_path)
    end
  end
end
