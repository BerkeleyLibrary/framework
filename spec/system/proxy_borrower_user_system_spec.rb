require 'rails_helper'

describe :forms_proxy_borrower_admin, type: :system do

  context 'specs with hardcoded admin' do
    # First create a DSP Rep:
    before(:all) do
      ProxyBorrowerUsers.delete_all
      @admin = ProxyBorrowerUsers.new
      @admin.id = 1
      @admin.lcasid = 112_233
      @admin.name = 'John Doe'
      @admin.role = 'Admin'
      @admin.save
    end

    # Go to the Admin Users View Page:
    before(:each) do
      # These functions require admin privledges:
      admin_user = User.new(uid: '1707532')
      allow_any_instance_of(ProxyBorrowerAdminController).to receive(:current_user).and_return(admin_user)

      visit forms_proxy_borrower_admin_users_path
    end

    it 'removes an admin user' do
      click_link 'Remove'
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

    it 'allows an non hardcoded admin access' do

    end
  end
end
