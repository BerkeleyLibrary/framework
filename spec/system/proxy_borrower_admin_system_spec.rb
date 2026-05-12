require 'capybara_helper'
require 'calnet_helper'

describe :forms_proxy_borrower_admin, type: :system do

  context 'specs with proxyborrower admin' do
    before do
      admin = FrameworkUsers.create(
        lcasid: CalnetHelper::TEST_UID,
        name: 'Test Admin',
        role: 'Admin'
      )

      Assignment.create(
        framework_users: admin,
        role: Role.proxyborrow_admin
      )

      user = FrameworkUsers.create(
        lcasid: 112_233,
        name: 'John Doe',
        role: 'Admin'
      )

      @assignment = Assignment.create(
        framework_users: user,
        role: Role.proxyborrow_admin
      )

      mock_login(CalnetHelper::TEST_UID)

      visit forms_proxy_borrower_admin_users_path
    end

    it 'removes an admin user' do
      accept_confirm 'Are you sure you want to delete John Doe?' do
        click_link 'Remove', match: :first
      end
      expect(page).to have_no_content('<div class="col user-col">John Doe')
      expect(page).to have_content('Removed John Doe from administrator list')
    end

    it 'adds a new admin user' do
      fill_in('lcasid', with: '12345678')
      fill_in('name', with: 'Jane Doe')
      submit_button = find(:xpath, "//input[@type='submit']")
      submit_button.click
      expect(page).to have_content('Jane Doe')
    end

  end
end
