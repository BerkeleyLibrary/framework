require 'capybara_helper'
require 'calnet_helper'

describe :service_article_request_forms, type: :system do
  describe 'with a valid user' do
    attr_reader :patron_id
    attr_reader :patron
    attr_reader :user

    let(:alma_api_key) { 'totally-fake-key' }

    before do
      @patron_id = Alma::Type.sample_id_for(Alma::Type::POST_DOC)
      @user = login_as_patron(patron_id)
      allow(Rails.application.config).to receive(:alma_api_key).and_return(alma_api_key)

      req_url = "https://api-na.hosted.exlibrisgroup.com/almaws/v1/users/#{patron_id}?apikey=totally-fake-key&expand=fees&view=full"

      stub_request(:get, req_url)
        .with(headers: { 'Accept' => 'application/json' })
        .to_return(status: 200, body: File.new("spec/data/alma_patrons/#{patron_id}.json"))

      @patron = Alma::User.find(patron_id)
      eligible = patron.find_note('book scan eligible') ? true : false

      expect(eligible).to eq(true) # just to be sure

      visit new_service_article_request_form_path
    end

    after do
      logout!
    end

    it 'links to the baker email address' do
      support_email = page.find(:xpath, "//a[@class='support-email']")
      expect(support_email['href']).to eq('mailto:baker@library.berkeley.edu')
    end

    it 'prepopulates the patron email as a required field' do
      expected_email = patron.email
      patron_email_field = find(:xpath, "//input[@id='service_article_request_form_patron_email']")
      expect(patron_email_field['value']).to eq(expected_email)
      expect(patron_email_field['required']).to be_truthy
    end

    it 'marks all required fields as required' do
      required_fields = %w[article_title display_name pub_title vol]
      required_fields.each do |field_name|
        field = find(:xpath, "//input[@id='service_article_request_form_#{field_name}']")
        expect(field['required']).to be_truthy
      end
    end

    it 'accepts a submission' do
      required_fields = %w[article_title display_name pub_title vol]
      required_fields.each do |field_name|
        fill_in("service_article_request_form_#{field_name}", with: "value for #{field_name}")
      end

      submit_button = find(:xpath, "//input[@type='submit']")
      submit_button.click

      expect(page).to have_current_path('/forms/altmedia-articles/confirmed')
    end
  end

  describe 'with an invalid patron type' do
    let(:alma_api_key) { 'totally-fake-key' }

    it 'throws patron not eligible error' do
      patron_id = Alma::Type.sample_id_for(Alma::Type::UNDERGRAD)
      login_as_patron(patron_id)
      allow(Rails.application.config).to receive(:alma_api_key).and_return(alma_api_key)

      req_url = "https://api-na.hosted.exlibrisgroup.com/almaws/v1/users/#{patron_id}?apikey=totally-fake-key&expand=fees&view=full"

      stub_request(:get, req_url)
        .with(headers: { 'Accept' => 'application/json' })
        .to_return(status: 200, body: File.new("spec/data/alma_patrons/#{patron_id}.json"))

      patron = Alma::User.find(patron_id)
      patron.delete_note('book scan eligible')

      visit new_service_article_request_form_path

      expect(page).to have_content('This article request form is for patrons who are eligible')
    end
  end
end
