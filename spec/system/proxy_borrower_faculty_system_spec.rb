require 'capybara_helper'
require 'calnet_helper'
require 'time'

describe :forms_proxy_borrower_faculty, type: :system do
  attr_reader :patron_id
  attr_reader :patron
  attr_reader :user

  let(:alma_api_key) { 'totally-fake-key' }

  let(:field_prefix) { 'proxy_borrower_requests_' }

  before(:all) do
    # Calculate and define the max date and an invalid date:
    @max_date = ProxyBorrowerRequests.max_term

    # Thou shalt pass parameters as Dates, since we use native date fields now:
    @invalid_date = Time.zone.today - 1.day
  end

  before do
    @patron_id = Alma::Type.sample_id_for(Alma::Type::FACULTY)
    @user = login_as_patron(patron_id)

    # Need to add the faculty affiliation and email for user:
    @user.affiliations = 'EMPLOYEE-TYPE-ACADEMIC'
    @user.email = 'notreal@nowhere.com'

    allow(Rails.application.config).to receive(:alma_api_key).and_return(alma_api_key)

    req_url = "https://api-na.hosted.exlibrisgroup.com/almaws/v1/users/#{patron_id}?expand=fees&view=full"

    stub_request(:get, req_url)
      .with(headers: { 'Accept' => 'application/json', 'Authorization' => "apikey #{alma_api_key}" })
      .to_return(status: 200, body: File.new("spec/data/alma_patrons/#{patron_id}.json"))

    @patron = Alma::User.find(patron_id)

    # And pass @user to the controller as the current_user:
    allow_any_instance_of(ProxyBorrowerFormsController).to receive(:current_user).and_return(@user)

    visit forms_proxy_borrower_faculty_path
  end

  after do
    logout!
  end

  it 'marks all required fields as required' do
    required_fields = %w[
      research_last
      research_first
      date_term
    ]

    required_fields.each do |field_name|
      field = find(:xpath, "//input[@id='#{field_prefix}#{field_name}']")
      expect(field['required']).to be_truthy
    end
  end

  it 'rejects a request with missing required data' do
    # TODO: instead of using spaces to get around the JavaScript empty check, test
    #       the JavaScript, then test the server-side validation in a request spec
    fill_in("#{field_prefix}research_last", with: ' ')
    fill_in("#{field_prefix}research_first", with: ' ')
    fill_in("#{field_prefix}date_term", with: @max_date)

    submit_button = find(:xpath, "//input[@type='submit']")
    submit_button.click

    expect(page).to have_content('Last name of (research assistant) proxy must not be blank')
    expect(page).to have_content('First name of (research assistant) proxy must not be blank')
  end

  it 'rejects a request with an invalid date term' do
    fill_in("#{field_prefix}research_last", with: 'Doe')
    fill_in("#{field_prefix}research_first", with: 'John')

    fill_in("#{field_prefix}date_term", with: @invalid_date)

    submit_button = find(:xpath, "//input[@type='submit']")
    submit_button.click

    expect(page).to have_content('The term of the Proxy Card must not be in the past')
  end

  it 'accepts a valid request' do
    fill_in("#{field_prefix}faculty_name", with: 'Brooks Hatlen')
    fill_in("#{field_prefix}department", with: 'KPADM')
    fill_in("#{field_prefix}research_last", with: 'Doe')
    fill_in("#{field_prefix}research_first", with: 'John')
    fill_in("#{field_prefix}date_term", with: @max_date)

    submit_button = find(:xpath, "//input[@type='submit']")
    submit_button.click

    expect(page).to have_current_path(forms_proxy_borrower_request_faculty_path, ignore_query: true)
    expect(page).to have_content('The form has been submitted')
  end
end
