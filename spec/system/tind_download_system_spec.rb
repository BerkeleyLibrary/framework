require 'capybara_helper'

describe TindDownloadController, type: :system do
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
      end

      it 'downloads a collection' do
        search_url = 'https://digicoll.lib.berkeley.edu/api/v1/search'
        search_params = { c: 'Abraham Lincoln Papers', format: "xml" }
        search_params_with_search_id = search_params.merge(search_id: "DnF1ZXJ5VGhlbkZldGNoBQAAAAABsY_zFklPYzRCNVRpUW9XTUxlLVV5TjhwLXcAAAAAAEuVxhY3YXhvOTVQblIzSzh1bTVEQXZ3OG9BAAAAAAP1GGgWd0pBX2NuQWhSM2FSTDhpQ1p4cWxyZwAAAAAEI7E5Fm5OeWNPSFNTUWsyLVBKQ3BVQS1kclEAAAAAAdZneBY5NXEyR0NQaVQ5MnRkQ29NcS15S1FB")
        result_1 = File.read('spec/data/tind_download/tind-abraham-lincoln-1.xml')
        result_2 = File.read('spec/data/tind_download/tind-abraham-lincoln-2.xml')
        stub_request(:get, search_url, params: search_params).to_return(status: 200, body: result_1)
        stub_request(:get, search_url, params: search_params_with_search_id).to_return(status: 200, body: result_2)

        Rspec::Expectations.fail_with('not implemented')
      end
    end
  end
end
