require 'capybara_helper'
require 'calnet_helper'

describe :libstaff_edevices_loan_forms, type: :system do
  describe 'with a valid user' do
    attr_reader :patron_id
    attr_reader :patron
    attr_reader :user

    let(:alma_api_key) { 'totally-fake-key' }

    before do
      @patron_id = Alma::Type.sample_id_for(Alma::Type::LIBRARY_STAFF)
      @user = login_as_patron(patron_id)
      allow(Rails.application.config).to receive(:alma_api_key).and_return(alma_api_key)

      req_url = "https://api-na.hosted.exlibrisgroup.com/almaws/v1/users/#{patron_id}?expand=fees&view=full"

      stub_request(:get, req_url)
        .with(headers: { 'Accept' => 'application/json', 'Authorization' => "apikey #{alma_api_key}" })
        .with(headers: { 'Accept' => 'application/json' })
        .to_return(status: 200, body: File.new("spec/data/alma_patrons/#{patron_id}.json"))

      @patron = Alma::User.find(patron_id)
      visit new_libstaff_edevices_loan_form_path
    end

    after do
      logout!
    end

    it 'links to the privileges desk email address' do
      support_email = page.find(:xpath, "//a[@class='support-email']")
      expect(support_email['href']).to eq('mailto:privdesk-library@berkeley.edu')
    end

    it 'displays the patron email as a read-only field' do
      expected_email = patron.email
      patron_email_field = find(:xpath, "//input[@id='libstaff_edevices_loan_form_patron_email']")
      expect(patron_email_field['value']).to eq(expected_email)
      expect(patron_email_field['readonly']).to be_truthy
    end

    it "displays the user's display name as a read-only field" do
      expected_name = user.display_name
      display_name_field = find(:xpath, "//input[@id='libstaff_edevices_loan_form_display_name']")
      expect(display_name_field['value']).to eq(expected_name)
      expect(display_name_field['readonly']).to be_truthy
    end

    it 'marks all checks as required' do
      checks = LibstaffEdevicesLoanForm.instance_methods.map(&:to_s).select { |n| n.end_with?('check') }
      checks.each do |check|
        check_field = find(:xpath, "//input[@id='libstaff_edevices_loan_form_#{check}']")
        expect(check_field['required']).to be_truthy
      end
    end

    it 'accepts a submission' do
      checks = LibstaffEdevicesLoanForm.instance_methods.map(&:to_s).select { |n| n.end_with?('check') }
      checks.each do |check|
        check_field = find(:xpath, "//input[@id='libstaff_edevices_loan_form_#{check}']")
        page.scroll_to(check_field)
        check_field.set(true)
      end

      submit_button = find(:xpath, "//input[@type='submit']")
      submit_button.click

      expect(page).to have_current_path('/forms/library-staff-devices/all_checked')
    end
  end
end
