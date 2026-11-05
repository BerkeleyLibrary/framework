require 'rails_helper'
require 'capybara_helper'
require 'calnet_helper'

describe LocationRequestsController, type: :system do

  shared_examples 'an off-hours only form' do
    it 'does not include the "immediate" radio group' do
      [true, false].each do |state|
        expected_id = "location_request_immediate_#{state}"
        expect(page).not_to have_selector("input[type=radio]##{expected_id}")
      end
    end
  end

  describe 'location requests alert' do
    let(:configured_alert) { nil }

    before do
      allow(Rails.configuration).to receive(:location_requests_alert).and_return(configured_alert)
      visit new_location_request_path
    end

    context 'when the alert is not configured' do
      it 'does not display a warning alert' do
        expect(page).to have_no_selector('div.alert.alert-warning[role="alert"]')
      end
    end

    context 'when the alert is configured' do
      let(:configured_alert) { 'OCLC requests are currently rate limited.' }

      it 'displays the configured warning alert' do
        expect(page).to have_selector('div.alert.alert-warning[role="alert"]', text: configured_alert)
      end
    end
  end

  shared_examples 'a form with immediate and off-hours options' do
    it 'includes the "immediate" radio group' do
      [true, false].each do |state|
        expected_id = "location_request_immediate_#{state}"
        expect(page).to have_selector("input[type=radio]##{expected_id}")
      end
    end

    it 'defaults to immediate: true' do
      visit immediate_location_request_path

      immediate_true_button = page.find(id: 'location_request_immediate_true')
      expect(immediate_true_button).to be_selected
    end
  end

  shared_examples 'a forbidden page' do
    it 'is forbidden' do
      expect(page).to have_content('not authorized')
    end
  end

  context 'as admin' do
    before { @user = login_as_patron(Alma::FRAMEWORK_ADMIN_ID) }

    after { logout! }

    describe :new do
      before { visit new_location_request_path }

      it_behaves_like 'a form with immediate and off-hours options'
    end

    describe :immediate do
      before { visit immediate_location_request_path }

      it_behaves_like 'a form with immediate and off-hours options'
    end
  end

  context 'with non-admin login' do
    before { @user = login_as_patron(Alma::NON_FRAMEWORK_ADMIN_ID) }

    after { logout! }

    describe :new do
      before { visit new_location_request_path }

      it_behaves_like 'an off-hours only form'
    end

    describe :immediate do
      before { visit immediate_location_request_path }

      it_behaves_like 'a forbidden page'
    end
  end

  context 'without login' do
    describe :new do
      before { visit new_location_request_path }

      it_behaves_like 'an off-hours only form'
    end

    describe :immediate do
      before { visit immediate_location_request_path }

      it 'requires login' do
        expect(page).to have_content('You need to log in to continue.')
      end
    end
  end
end
