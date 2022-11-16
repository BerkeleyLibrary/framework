require 'capybara_helper'
require 'calnet_helper'

describe :scan_request_forms, type: :system do
  describe 'with a valid user' do
    attr_reader :patron_id
    attr_reader :patron
    attr_reader :user

    let(:alma_api_key) { 'totally-fake-key' }

    before do
      @patron_id = Alma::Type.sample_id_for(Alma::Type::FACULTY)
      @user = login_as_patron(patron_id)
      allow(Rails.application.config).to receive(:alma_api_key).and_return(alma_api_key)

      req_url = "https://api-na.hosted.exlibrisgroup.com/almaws/v1/users/#{patron_id}?apikey=totally-fake-key&expand=fees&view=full"

      stub_request(:get, req_url)
        .with(headers: { 'Accept' => 'application/json' })
        .to_return(status: 200, body: File.new("spec/data/alma_patrons/#{patron_id}.json"))

      @patron = Alma::User.find(patron_id)
      visit new_scan_request_form_path
    end

    after do
      logout!
    end

    it 'links to the prntscan email address' do
      support_email = page.find(:xpath, "//a[@class='support-email']")
      expect(support_email['href']).to eq('mailto:prntscan@lists.berkeley.edu')
    end

    it 'defaults to opt-in' do
      opt_in_button = find(:xpath, "//input[@id='scan_request_form_opt_in_true']")
      expect(opt_in_button).to be_checked

      opt_out_button = find(:xpath, "//input[@id='scan_request_form_opt_in_false']")
      expect(opt_out_button).not_to be_checked
    end

    it 'accepts opt-in' do
      choose('scan_request_form_opt_in_true')

      submit_button = find(:xpath, "//input[@type='submit']")
      submit_button.click

      expect(page).to have_current_path('/forms/altmedia/optin')
    end

    it 'accepts opt-out' do
      choose('scan_request_form_opt_in_false')

      submit_button = find(:xpath, "//input[@type='submit']")
      submit_button.click

      expect(page).to have_current_path('/forms/altmedia/optout')
    end
  end
end
