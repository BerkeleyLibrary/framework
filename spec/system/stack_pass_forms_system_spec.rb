require 'rails_helper'
require 'time'

describe :stack_pass_form, type: :system do

  before(:each) do
    # Clear the way:
    StackPassForm.delete_all
  end

  context 'request specs' do
    it 'marks all required fields as required' do
      visit new_stack_pass_form_path

      required_fields = %w[
        stack_pass_form_name
        stack_pass_form_email
        stack_pass_form_pass_date
        stack_pass_form_local_id
      ]
      required_fields.each do |field_name|
        field = find(:xpath, "//input[@id='#{field_name}']")
        expect(field['required']).to be_truthy
      end
    end

    it 'accepts a valid request' do
      visit new_stack_pass_form_path
      fill_in('stack_pass_form_name', with: 'John Doe')
      fill_in('stack_pass_form_email', with: 'jdoe@library.edu')
      fill_in('stack_pass_form_phone', with: '925-555-9999')
      fill_in('stack_pass_form_pass_date', with: '04/13/25')
      fill_in('stack_pass_form_local_id', with: '123456789')
      choose('stack_pass_form_main_stack_yes')

      submit_button = find(:xpath, "//input[@type='submit']")
      submit_button.click

      expect(page).to have_content('Your request for a Stack Pass has been submitted')
    end

    it 'fails a request with an incorrectly formatted date' do
      visit new_stack_pass_form_path
      fill_in('stack_pass_form_name', with: 'John Doe')
      fill_in('stack_pass_form_email', with: 'jdoe@library.edu')
      fill_in('stack_pass_form_phone', with: '925-555-9999')
      fill_in('stack_pass_form_pass_date', with: '04---13---1996')
      fill_in('stack_pass_form_local_id', with: '123456789')
      choose('stack_pass_form_main_stack_yes')

      submit_button = find(:xpath, "//input[@type='submit']")
      submit_button.click

      expect(page).to have_content('Your request for a Stack Pass has been submitted')
    end

    it 'fails a request with a bad email address' do
      visit new_stack_pass_form_path
      fill_in('stack_pass_form_name', with: 'John Doe')
      fill_in('stack_pass_form_email', with: 'NOT-AN-EMAIL-ADDRESS')
      fill_in('stack_pass_form_phone', with: '925-555-9999')
      fill_in('stack_pass_form_pass_date', with: '04/13/1996')
      fill_in('stack_pass_form_local_id', with: '123456789')
      choose('stack_pass_form_main_stack_yes')

      submit_button = find(:xpath, "//input[@type='submit']")
      submit_button.click

      expect(page).to have_content('is not a valid email address')
    end
  end

  context 'approve/deny specs' do

    before(:each) do
      # Clear the way:
      StackPassForm.delete_all

      # Create some requests:
      StackPassForm.create(id: 1, email: 'openreq@test.com', name: 'John Doe',
                           phone: '925-555-1234', pass_date: Date.today, main_stack: true, local_id: '8675309')

      # These functions require admin privledges:
      admin_user = User.new(display_name: 'Test Admin', uid: '1707532', affiliations: ['EMPLOYEE-TYPE-ACADEMIC'])
      allow_any_instance_of(StackPassFormsController).to receive(:current_user).and_return(admin_user)

      visit '/forms/stack-pass/1'
    end

    it 'allows an admin to deny a request' do
      # Fill in the fields:
      choose('stack_pass_deny')
      select('Too many passes requested', from: 'stack_pass_denial_denial_reason', visible: :all)
      fill_in('approved_by', with: 'ADMIN USER')

      # Submit:
      submit_button = find(:xpath, "//input[@type='submit']")
      submit_button.click

      # Verify Results:
      expect(page).to have_content('This request has been processed')
    end

    it 'allows an admin to approve a request' do
      # Fill in the fields:
      choose('stack_pass_approve')
      fill_in('approved_by', with: 'ADMIN USER')

      # Submit:
      submit_button = find(:xpath, "//input[@type='submit']")
      submit_button.click

      # Verify Results:
      expect(page).to have_content('This request has been processed')
    end
  end

end
