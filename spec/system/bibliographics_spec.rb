require 'capybara_helper'
require 'calnet_helper'

RSpec.describe 'Bibliographics', type: :system do

  describe 'unauthenticated user' do
    it 'redirects to login' do
      visit bibliographics_path
      expected_path = "#{omniauth_callback_path(:calnet)}?#{URI.encode_www_form(origin: bibliographics_path)}"
      expect(page).to have_current_path(expected_path)
    end
  end

  describe 'authenticated but unauthorized user' do
    # TODO: replace with around(:each) using with_patron_login() once we're on Rails 6.1
    #       (see CapybaraHelper::GridConfigurator#configure!)
    before { login_as_patron(Alma::Type.sample_id_for(Alma::Type::FACULTY)) }

    after { logout! }

    it 'returns 403 unauthorized' do
      visit bibliographics_path
      expect(page).to have_content('You are not authorized to access this page.')
    end
  end

  describe 'authenticated user' do
    after { logout! }

    shared_examples 'an authorized user' do
      it 'displays the form' do
        visit bibliographics_path
        expect(page).to have_content("Please choose a '.txt'")
      end
    end

    context 'specs for Framework admins' do
      before do
        login_as_patron(Alma::FRAMEWORK_ADMIN_ID)
      end

      it_behaves_like 'an authorized user'
    end

    context 'specs for Alma admins' do
      before do
        login_as_patron(Alma::ALMA_ADMIN_ID)
      end

      it_behaves_like 'an authorized user'
    end
  end

end
