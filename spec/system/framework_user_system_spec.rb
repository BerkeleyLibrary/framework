require 'capybara_helper'

describe :forms_proxy_borrower_admin, type: :system do

  context 'specs with hardcoded admin' do
    before(:each) do
      # First create a DSP Rep and assignment
      @user = FrameworkUsers.create(id: 1, lcasid: 112_233, name: 'John Doe', role: 'Admin')
      @role = Role.create(id: 1, role: 'proxyborrow_admin')
      @assignment = Assignment.create(framework_users_id: 1, role_id: 1)

      # These functions require admin privledges:
      admin_user = User.new(uid: '1707532')
      allow_any_instance_of(ProxyBorrowerAdminController).to receive(:current_user).and_return(admin_user)

      # Go to the Admin Users View Page:
      visit forms_proxy_borrower_admin_users_path
    end

    it 'removes an admin user' do
      accept_confirm 'Are you sure you want to delete John Doe?' do
        click_link 'Remove'
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

describe :forms_stack_pass_admin, type: :system do
  context 'specs with hardcoded admin' do
    before(:each) do
      # First create an admin and assignment
      FrameworkUsers.create(id: 1, lcasid: 112_233, name: 'John Doe', role: 'Admin')
      Role.create(id: 1, role: 'proxyborrow_admin')
      Role.create(id: 2, role: 'stackpass_admin')
      Assignment.create(framework_users_id: 1, role_id: 2)

      # These functions require admin privledges:
      admin_user = User.new(uid: '1707532')
      allow_any_instance_of(StackPassAdminController).to receive(:current_user).and_return(admin_user)

      # Go to the Admin Users View Page:
      visit forms_stack_pass_admin_users_path
    end

    it 'removes an admin user' do
      accept_confirm 'Are you sure you want to delete John Doe?' do
        click_link 'Remove'
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
