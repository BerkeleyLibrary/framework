require 'capybara_helper'
require 'calnet_helper'
require 'time'

describe :tind_marc_batch, type: :system do
  let(:alma_api_key) { 'not-a-real-api-key' }

  describe 'unauthenticated user' do
    it 'redirects to login' do
      visit tind_marc_batch_path
      expected_path = "#{omniauth_callback_path(:calnet)}?#{URI.encode_www_form(origin: tind_marc_batch_path)}"
      expect(page).to have_current_path(expected_path)
    end
  end

  describe 'authenticated user' do
    before do
      # login_as_patron(Alma::ALMA_ADMIN_ID)
      @current_user = login_as_patron(Alma::ALMA_ADMIN_ID)
      @current_user.email = 'notreal@nowhere.com'

      # And pass @user to the controller as the current_user:
      allow_any_instance_of(TindMarcBatchController).to receive(:current_user).and_return(@current_user)
    end

    after { logout! }

    it 'displays the form' do
      visit tind_marc_batch_path
      expect(page).to have_content('Tind MARC Batch Load Tool')
    end

    it 'marks required fields as required' do
      visit tind_marc_batch_path
      required_input_fields = %w[
        directory
        library
        initials
        f_980_a
        f_982_a
        f_982_b
      ]
      required_input_fields.each do |field_name|
        field = find(:xpath, "//input[@id='#{field_name}']")
        expect(field['required']).to be_truthy
      end

      field = find(:xpath, "//textarea[@id='f_540_a']")
      expect(field['required']).to be_truthy

      field = find(:xpath, "//select[@id='resource_type']")
      expect(field['required']).to be_truthy
    end

    describe 'the form' do
      it 'brings up an error message if the directory does not exist' do
        visit tind_marc_batch_path
        fill_in('directory', with: 'non-existent/directory')
        fill_in('library', with: 'LIBRARY')
        fill_in('initials', with: 'DMZ')
        fill_in('f_980_a', with: 'facet')
        fill_in('f_982_a', with: 'short name')
        fill_in('f_982_b', with: 'long name')
        fill_in('f_540_a', with: 'rights statment')
        find('#resource_type').find(:xpath, 'option[2]').select_option
        button = find(:xpath, "//input[@type='submit']")
        button.click
        expect(page).to have_content('Path is invalid')
      end

      it 'accepts a valid request' do
        visit tind_marc_batch_path
        fill_in('directory', with: 'librettos/incoming')
        fill_in('library', with: 'LIBRARY')
        fill_in('initials', with: 'DMZ')
        fill_in('f_980_a', with: 'facet')
        fill_in('f_982_a', with: 'short name')
        fill_in('f_982_b', with: 'long name')
        fill_in('f_540_a', with: 'rights statment')
        find('#resource_type').find(:xpath, 'option[2]').select_option
        button = find(:xpath, "//input[@type='submit']")
        button.click
        expect(page).to have_content('Your Tind MARC batch load has been submitted')
      end
    end
  end
end
