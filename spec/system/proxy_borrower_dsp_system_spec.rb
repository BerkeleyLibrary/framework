require 'capybara_helper'
require 'calnet_helper'
require 'time'

describe :forms_proxy_borrower_dsp, type: :system do
  attr_reader :patron_id
  attr_reader :patron
  attr_reader :user

  let(:alma_api_key) { 'totally-fake-key' }

  before(:all) do
    # Calculate and define the max date and an invalid date:
    today = Date.current
    mo = today.month
    yr = today.year
    yr += 1 if mo >= 4
    max_date = Date.new(yr, 6, 30)

    # Thou shalt pass paramters as strings:
    @invalid_date_str = Date.new(yr, 7, 0o1).strftime('%m/%d/%Y')
    @max_date_str = max_date.strftime('%m/%d/%Y')
  end

  before do
    @patron_id = Alma::Type.sample_id_for(Alma::Type::UNDERGRAD_SLE)
    @user = login_as_patron(patron_id)
    allow(Rails.application.config).to receive(:alma_api_key).and_return(alma_api_key)

    req_url = "https://api-na.hosted.exlibrisgroup.com/almaws/v1/users/#{patron_id}?apikey=totally-fake-key&expand=fees&view=full"

    stub_request(:get, req_url)
      .with(headers: { 'Accept' => 'application/json' })
      .to_return(status: 200, body: File.new("spec/data/alma_patrons/#{patron_id}.json"))

    @patron = Alma::User.find(patron_id)

    visit forms_proxy_borrower_dsp_path
  end

  after do
    logout!
  end

  it 'marks all required fields as required' do
    required_fields = %w[
      research_last
      research_first
      term
      dsp_rep
    ]

    # Check required text fields:
    required_fields.each do |field_name|
      field = find(:xpath, "//input[@id='#{field_name}']")
      expect(field['required']).to be_truthy
    end

  end

  it 'rejects a request with missing required data' do
    # TODO: instead of using spaces to get around the JavaScript empty check, test
    #       the JavaScript, then test the server-side validation in a request spec
    fill_in('student_name', with: ' ')
    fill_in('research_last', with: ' ')
    fill_in('research_first', with: ' ')
    fill_in('dsp_rep', with: ' ') # TODO: add server-side validation for this (currently only JS)
    fill_in('term', with: "#{@max_date_str}\t") # \t to tab off date field

    submit_button = find(:xpath, "//input[@type='submit']")
    submit_button.click

    expect(page).to have_content('Last name of proxy must not be blank')
    expect(page).to have_content('First name of proxy must not be blank')
  end

  it 'rejects a request with a non-date term' do
    fill_in('student_name', with: 'Luke Skywalker')
    fill_in('research_last', with: 'Doe')
    fill_in('research_first', with: 'John')
    fill_in('dsp_rep', with: 'Jane Roe')

    fill_in('term', with: "33333333\t") # \t to tab off date field

    submit_button = find(:xpath, "//input[@type='submit']")
    submit_button.click

    expect(page).to have_content('Term of proxy card must not be blank and must be in the format mm/dd/yyyy')
  end

  it 'rejects a request with an invalid date term' do
    fill_in('student_name', with: 'Luke Skywalker')
    fill_in('research_last', with: 'Doe')
    fill_in('research_first', with: 'John')
    fill_in('dsp_rep', with: 'Jane Roe')

    fill_in('term', with: "#{@invalid_date_str}\t") # \t to tab off date field

    submit_button = find(:xpath, "//input[@type='submit']")
    submit_button.click

    today = Date.current
    year = today.month >= 4 ? today.year + 1 : today.year
    expected_max = Date.new(year, 6, 30).strftime('%B %e, %Y')

    expect(page).to have_content("The term of the Proxy Card must not be greater than #{expected_max}")
  end

  it 'accepts a valid request' do
    fill_in('student_name', with: 'Luke Skywalker')
    fill_in('research_last', with: 'Doe')
    fill_in('research_first', with: 'John')
    fill_in('dsp_rep', with: 'Jane Roe')
    fill_in('term', with: "#{@max_date_str}\t") # \t to tab off date field

    submit_button = find(:xpath, "//input[@type='submit']")
    submit_button.click

    expect(page).to have_current_path(forms_proxy_borrower_request_dsp_path, ignore_query: true)
    expect(page).to have_content('The form has been submitted')
  end

end
