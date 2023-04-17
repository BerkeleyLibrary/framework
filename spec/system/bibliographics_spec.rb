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

  describe 'authenticated non-staff user' do
    # TODO: replace with around(:each) using with_patron_login() once we're on Rails 6.1
    #       (see CapybaraHelper::GridConfigurator#configure!)
    before { login_as_patron(Alma::Type.sample_id_for(Alma::Type::FACULTY)) }

    after { logout! }

    it 'returns 403 unauthorized' do
      visit bibliographics_path
      expect(page).to have_content('Only UC Berkeley staff may access.')
    end
  end

  describe 'authenticated user' do
    before do
      login_as_patron(Alma::Type.sample_id_for(Alma::Type::STAFF))
      visit bibliographics_path
    end

    after { logout! }

    it 'displays the form' do
      expect(page).to have_content("Please choose a '.txt'")
    end

  end

end
