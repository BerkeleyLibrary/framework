require 'capybara_helper'
require 'calnet_helper'

describe TindDownloadController, type: :system do
  describe 'unauthenticated user' do
    it 'redirects to login' do
      visit tind_download_path
      expected_path = "#{omniauth_callback_path(:calnet)}?#{URI.encode_www_form(origin: tind_download_path)}"
      expect(page).to have_current_path(expected_path)
    end
  end

  describe 'authenticated non-staff user' do
    around(:each) do |example|
      patron_id = Patron::Type.sample_id_for(Patron::Type::FACULTY)
      with_patron_login(patron_id) { example.run }
    end

    it 'returns 403 unauthorized' do
      visit tind_download_path
      expect(page).to have_content('Restricted to University staff')
    end
  end

  describe 'authenticated staff user' do
    around(:each) do |example|
      patron_id = Patron::Type.sample_id_for(Patron::Type::STAFF)
      with_patron_login(patron_id) { example.run }
    end

    before(:each) do
      stub_request(:get, 'https://digicoll.lib.berkeley.edu/api/v1/collections?depth=100').to_return(
        status: 200,
        body: File.new('spec/data/tind_download/collections.json')
      )

      visit tind_download_path
    end

    it 'displays the form' do
      expect(page).to have_content('TIND Metadata Download')
    end

    describe 'download button' do
      it 'defaults to disabled' do
        expect(page).to have_button('Download Metadata', disabled: true)
      end

      it 'is enabled once a collection name is entered' do
        fill_in('collection_name', with: 'Abraham Lincoln Papers')
        expect(page).to have_button('Download Metadata', disabled: false)
      end

      describe 'downloads' do
        before(:each) do
          search_url = 'https://digicoll.lib.berkeley.edu/api/v1/search'
          search_params = { c: 'Abraham Lincoln Papers', format: "xml" }
          search_params_with_search_id = search_params.merge(search_id: "DnF1ZXJ5VGhlbkZldGNoBQAAAAABsY_zFklPYzRCNVRpUW9XTUxlLVV5TjhwLXcAAAAAAEuVxhY3YXhvOTVQblIzSzh1bTVEQXZ3OG9BAAAAAAP1GGgWd0pBX2NuQWhSM2FSTDhpQ1p4cWxyZwAAAAAEI7E5Fm5OeWNPSFNTUWsyLVBKQ3BVQS1kclEAAAAAAdZneBY5NXEyR0NQaVQ5MnRkQ29NcS15S1FB")
          result_1 = File.read('spec/data/tind_download/tind-abraham-lincoln-1.xml')
          result_2 = File.read('spec/data/tind_download/tind-abraham-lincoln-2.xml')
          stub_request(:get, search_url).with(query: search_params).to_return(status: 200, body: result_1)
          stub_request(:get, search_url).with(query: search_params_with_search_id).to_return(status: 200, body: result_2)

          fill_in('collection_name', with: 'Abraham Lincoln Papers')
        end

        it 'downloads a CSV' do
          page.choose('export_format_csv')
          page.click_button('Download Metadata')

          expected_filename = 'abraham-lincoln-papers.csv'
          downloaded_file_path = File.join(CapybaraHelper.download_path, expected_filename)

          # TODO: get this working
          expect(File.exist?(downloaded_file_path)).to eq(true)

          actual = File.read(downloaded_file_path)
          expected = File.read(File.join('spec/data/tind_download', expected_filename))
          expect(actual).to eq(expected)
        end
      end
    end
  end
end
