require 'capybara_helper'
require 'calnet_helper'
require 'time'

describe :alma_item_set, type: :system do
  let(:alma_api_key) { 'not-a-real-api-key' }

  describe 'unauthenticated user' do
    it 'requires login' do
      visit alma_item_set_path
      expect(page).to have_content('You need to log in to continue.')
    end
  end

  describe 'authenticated user' do
    before do
      login_as_patron(Alma::ALMA_ADMIN_ID)

      allow(Rails.application.config).to receive(:alma_api_key).and_return(alma_api_key)

      stub_request(:get, 'https://api-na.hosted.exlibrisgroup.com/almaws/v1/conf/sets?content_type=ITEM&expand=none&limit=100&offset=0&view=full').to_return(
        status: 200,
        body: File.new('spec/data/alma_items/item_set_1.json')
      )

      stub_request(:get, 'https://api-na.hosted.exlibrisgroup.com/almaws/v1/conf/sets?content_type=ITEM&expand=none&limit=100&offset=100&view=full').to_return(
        status: 200,
        body: File.new('spec/data/alma_items/item_set_1.json')
      )
    end

    after { logout! }

    it 'displays the form' do
      visit alma_item_set_path
      expect(page).to have_content('Item Record Internal Note Prepender')
    end

    it 'marks required fields as required' do
      visit alma_item_set_path

      required_fields = %w[
        note_value
        initials
      ]
      required_fields.each do |field_name|
        field = find(:xpath, "//input[@id='#{field_name}']")
        expect(field['required']).to be_truthy
      end
    end

    describe 'append button' do
      it 'defaults to disabled' do
        visit alma_item_set_path
        expect(find(:xpath, "//input[@type='submit']")).to be_disabled
      end

      it 'is enabled when required fields are populated' do
        visit alma_item_set_path
        fill_in('note_value', with: 'Test Note Value')
        fill_in('initials', with: 'SMS')
        expect(find(:xpath, "//input[@type='submit']")).not_to be_disabled
      end
    end

    describe 'the form' do
      it 'accepts a valid request' do
        visit alma_item_set_path
        fill_in('note_value', with: 'Test Note Value')
        fill_in('initials', with: 'SMS')
        button = find(:xpath, "//input[@type='submit']")
        button.click
        expect(page).to have_content('Your request has been submitted')
      end

    end

  end
end
