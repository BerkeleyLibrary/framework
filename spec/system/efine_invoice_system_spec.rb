require 'capybara_helper'
require 'calnet_helper'

describe FinesController, type: :system do
  let(:alma_api_key) { 'fake-api-key' }
  let(:request_headers) { { 'Accept' => 'application/json', 'Authorization' => "apikey #{alma_api_key}" } }

  context 'authenticated alma_admin user' do
    before do
      login_as_patron(Alma::ALMA_ADMIN_ID)
      visit efines_path
    end

    after { logout! }

    it 'displays the form' do
      expect(page).to have_content('Non UC Berkeley Patron Fee Payments')
    end

    it 'displays user info and fees' do
      stub_request(:get, 'https://api-na.hosted.exlibrisgroup.com/almaws/v1/users/10335026?expand=fees&view=full')
        .with(headers: request_headers)
        .to_return(status: 200, body: File.new('spec/data/fines/efine-lookup-data.json'))

      stub_request(:get, 'https://api-na.hosted.exlibrisgroup.com/almaws/v1/users/10335026/fees')
        .with(headers: request_headers)
        .to_return(status: 200, body: File.new('spec/data/fines/efine-lookup-fees.json'))

      fill_in('alma_id', with: '10335026')
      submit_button = find(:xpath, "//input[@type='submit']")
      submit_button.click

      expect(page).to have_content("User's Info")
      expect(page).to have_content('Steven M Sullivan')
    end

  end

  context 'send request form' do
    before do
      login_as_patron(Alma::ALMA_ADMIN_ID)

      stub_request(:get, 'https://api-na.hosted.exlibrisgroup.com/almaws/v1/users/10335026?expand=fees&view=full')
        .with(headers: request_headers)
        .to_return(status: 200, body: File.new('spec/data/fines/efine-lookup-data.json'))

      stub_request(:get, 'https://api-na.hosted.exlibrisgroup.com/almaws/v1/users/10335026/fees')
        .with(headers: request_headers)
        .to_return(status: 200, body: File.new('spec/data/fines/efine-lookup-fees.json'))

      visit '/efines/lookup?alma_id=10335026'
    end

    it 'sends email to user' do
      submit_button = find(:xpath, "//input[@type='submit']")
      submit_button.click
      expect(page).to have_content('Email Sent')
    end
  end
end
