require 'rails_helper'
require 'capybara_helper'
require 'calnet_helper'

describe HoldingsRequestsController, type: :system do

  shared_examples 'an off-hours only form' do
    it 'does not include the "immediate" radio group' do
      [true, false].each do |state|
        expected_id = "holdings_request_immediate_#{state}"
        expect(page).not_to have_selector("input[type=radio]##{expected_id}")
      end
    end
  end

  shared_examples 'a form with immediate and off-hours options' do
    it 'includes the "immediate" radio group' do
      [true, false].each do |state|
        expected_id = "holdings_request_immediate_#{state}"
        expect(page).to have_selector("input[type=radio]##{expected_id}")
      end
    end

    it 'defaults to immediate: true' do
      visit immediate_holdings_request_path

      immediate_true_button = page.find(id: 'holdings_request_immediate_true')
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
      before { visit new_holdings_request_path }

      it_behaves_like 'a form with immediate and off-hours options'
    end

    describe :immediate do
      before { visit immediate_holdings_request_path }

      it_behaves_like 'a form with immediate and off-hours options'
    end
  end

  context 'with non-admin login' do
    before { @user = login_as_patron(Alma::NON_FRAMEWORK_ADMIN_ID) }

    after { logout! }

    describe :new do
      before { visit new_holdings_request_path }

      it_behaves_like 'an off-hours only form'
    end

    describe :immediate do
      before { visit immediate_holdings_request_path }

      it_behaves_like 'a forbidden page'
    end
  end

  context 'without login' do
    describe :new do
      before { visit new_holdings_request_path }

      it_behaves_like 'an off-hours only form'
    end

    describe :immediate do
      before { visit immediate_holdings_request_path }

      it 'redirects to login' do
        expected_path = "#{omniauth_callback_path(:calnet)}?#{URI.encode_www_form(origin: immediate_holdings_request_path)}"
        expect(page).to have_current_path(expected_path)
      end
    end
  end
end
