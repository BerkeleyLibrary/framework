require 'capybara_helper'
require 'calnet_helper'
require 'support/build_info_context'

describe :home, type: :system do
  describe :health do
    it 'does something sensible for a general error' do
      expect(Health::Check).to receive(:new).and_raise('Something went wrong')
      visit health_path
      expect(page).to have_content('Internal Server Error')
    end
  end

  describe :admin do
    context 'without login' do
      it 'redirects to login' do
        visit admin_path

        expected_path = "#{omniauth_callback_path(:calnet)}?#{URI.encode_www_form(origin: admin_path)}"
        expect(page).to have_current_path(expected_path)
      end
    end
  end

  describe :build_info do
    include_context 'mock build info'

    before do
      allow(BuildInfo).to receive(:build_info).and_return(@info)
    end

    it 'includes build info' do
      visit build_info_path

      info.to_h.each do |k, v|
        expected_id = "build-info-#{k.downcase}"
        info_row = page.find(:xpath, "//tr[@id='#{expected_id}']")
        v_str = v.to_s
        if v.is_a?(URI)
          expect(info_row).to have_link(v_str, href: v_str)
        else
          expect(info_row).to have_content(v_str)
        end
      end
    end
  end
end
