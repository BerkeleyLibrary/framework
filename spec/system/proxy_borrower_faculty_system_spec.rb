require 'calnet_helper'
require 'rails_helper'
require 'time'

describe :forms_proxy_borrower_faculty, type: :system do
  attr_reader :patron_id
  attr_reader :patron
  attr_reader :user

  before(:all) do
    # Calculate and define the max date and an invalid date:
    today = Date.today
    mo = today.month
    yr = today.year
    yr += 1 if mo >= 4
    max_date = Date.new(yr, 6, 30)

    # Thou shalt pass paramters as strings:
    @invalid_date_str = Date.new(yr, 7, 0o1).strftime('%m/%d/%Y')
    @max_date_str = max_date.strftime('%m/%d/%Y')
  end

  before(:each) do
    @patron_id = Patron::Type.sample_id_for(Patron::Type::FACULTY)
    @user = login_as(patron_id)

    # Need to add the faculty affiliation and email for user:
    @user.affiliations = 'EMPLOYEE-TYPE-ACADEMIC'
    @user.email = 'notreal@nowhere.com'

    @patron = Patron::Record.find(patron_id)

    # And pass @user to the controller as the current_user:
    allow_any_instance_of(ProxyBorrowerFormsController).to receive(:current_user).and_return(@user)

    visit forms_proxy_borrower_faculty_path
  end

  after(:each) do
    logout!
  end

  it 'marks all required fields as required' do
    required_fields = %w[
      research_last
      research_first
      term
    ]

    required_fields.each do |field_name|
      field = find(:xpath, "//input[@id='#{field_name}']")
      expect(field['required']).to be_truthy
    end
  end

  it 'rejects a request with missing required data' do
    fill_in('research_last', with: nil)
    fill_in('research_first', with: nil)
    fill_in('term', with: @max_date_str)

    submit_button = find(:xpath, "//input[@type='submit']")
    submit_button.click

    expect(page).to have_content('Last name of proxy must not be blank')
    expect(page).to have_content('First name of proxy must not be blank')
  end

  it 'rejects a request with a non-date term' do
    fill_in('research_last', with: 'Doe')
    fill_in('research_first', with: 'John')

    fill_in('term', with: 'NOT A DATE')

    submit_button = find(:xpath, "//input[@type='submit']")
    submit_button.click

    expect(page).to have_content('Term of proxy card must not be blank and must be in the format mm/dd/yyyy')
  end

  it 'rejects a request with an invalid date term' do
    fill_in('research_last', with: 'Doe')
    fill_in('research_first', with: 'John')

    fill_in('term', with: @invalid_date_str)

    submit_button = find(:xpath, "//input[@type='submit']")
    submit_button.click

    expect(page).to have_content('The term of the Proxy Card must not be greater than')
  end

  it 'accepts a valid request' do
    fill_in('faculty_name', with: 'Brooks Hatlen')
    fill_in('department', with: 'LIB')
    fill_in('research_last', with: 'Doe')
    fill_in('research_first', with: 'John')
    fill_in('term', with: @max_date_str)

    submit_button = find(:xpath, "//input[@type='submit']")
    submit_button.click

    expect(page.current_path).to eq(forms_proxy_borrower_request_faculty_path)
    expect(page).to have_content('The form has been submitted')
  end

  it 'accepts a valid request with a 2 digit year' do

    today = Date.today
    mo = today.month
    yr = today.year
    yr += 1 if mo >= 4

    # grab last 2 digits from year
    yr_str = yr.to_s
    @short_year = "6/30/#{yr_str[2..3]}"

    fill_in('faculty_name', with: 'Brooks Hatlen')
    fill_in('department', with: 'LIB')
    fill_in('research_last', with: 'Doe')
    fill_in('research_first', with: 'John')
    fill_in('term', with: @short_year)

    submit_button = find(:xpath, "//input[@type='submit']")
    submit_button.click

    expect(page.current_path).to eq(forms_proxy_borrower_request_faculty_path)
    expect(page).to have_content('The form has been submitted')
  end
end
