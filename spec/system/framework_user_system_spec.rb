require 'rails_helper'

describe :forms_proxy_borrower_admin, type: :system do

  context 'specs with hardcoded admin' do
    # First create a DSP Rep and assignment
    before(:all) do
      # Clear the way:
      Assignment.delete_all
      Role.delete_all
      FrameworkUsers.delete_all

      # Create User, Role and Assignment:
      FrameworkUsers.create(id: 1, lcasid: 112_233, name: 'John Doe', role: 'Admin')
      Role.create(id: 1, role: 'proxyborrow_admin')
      Assignment.create(framework_users_id: 1, role_id: 1)
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

  end
end

describe :forms_stack_pass_admin, type: :system do
  context 'specs with hardcoded admin' do
    # First create an admin and assignment
    before(:all) do
      # Clear the way:
      Assignment.delete_all
      Role.delete_all
      FrameworkUsers.delete_all

      # Create User, Role and Assignment:
      FrameworkUsers.create(id: 1, lcasid: 112_233, name: 'John Doe', role: 'Admin')
      Role.create(id: 1, role: 'proxyborrow_admin')
      Role.create(id: 2, role: 'stackpass_admin')
      Assignment.create(framework_users_id: 1, role_id: 2)
    end

    # Go to the Admin Users View Page:
    before(:each) do
      # These functions require admin privledges:
      admin_user = User.new(uid: '1707532')
      allow_any_instance_of(StackPassAdminController).to receive(:current_user).and_return(admin_user)

      visit forms_stack_pass_admin_users_path
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

  end
end
