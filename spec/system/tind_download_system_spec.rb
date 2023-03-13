require 'capybara_helper'
require 'calnet_helper'
require 'roo'

describe TindDownloadController, type: :system do
  before do
    allow(BerkeleyLibrary::TIND::Config).to receive(:api_key).and_return('not-a-real-api-key')
  end

  describe 'unauthenticated user' do
    it 'redirects to login' do
      visit tind_download_path
      expected_path = "#{omniauth_callback_path(:calnet)}?#{URI.encode_www_form(origin: tind_download_path)}"
      expect(page).to have_current_path(expected_path)
    end
  end

  describe 'authenticated non-staff user' do
    # TODO: replace with around(:each) using with_patron_login() once we're on Rails 6.1
    #       (see CapybaraHelper::GridConfigurator#configure!)
    before { login_as_patron(Alma::Type.sample_id_for(Alma::Type::FACULTY)) }

    after { logout! }

    it 'returns 403 unauthorized' do
      visit tind_download_path
      expect(page).to have_content('Restricted to University staff')
    end
  end

  describe 'authenticated staff user' do
    # TODO: replace with around(:each) using with_patron_login() once we're on Rails 6.1
    #       (see CapybaraHelper::GridConfigurator#configure!)
    before do
      login_as_patron(Alma::Type.sample_id_for(Alma::Type::STAFF))

      stub_request(:get, 'https://digicoll.lib.berkeley.edu/api/v1/collections?depth=100').to_return(
        status: 200,
        body: File.new('spec/data/tind_download/collections.json')
      )

      visit tind_download_path
    end

    after { logout! }

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
        before do
          search_id = 'DnF1ZXJ5VGhlbkZldGNoBQAAAAABsY'
          search_url = 'https://digicoll.lib.berkeley.edu/api/v1/search'
          search_params = { c: 'Abraham Lincoln Papers', format: 'xml' }
          search_params_with_search_id = search_params.merge(search_id:)
          result_1 = File.read('spec/data/tind_download/tind-abraham-lincoln-1.xml')
          result_2 = File.read('spec/data/tind_download/tind-abraham-lincoln-2.xml')
          stub_request(:get, search_url).with(query: search_params).to_return(status: 200, body: result_1)
          stub_request(:get, search_url).with(query: search_params_with_search_id).to_return(status: 200, body: result_2)

          fill_in('collection_name', with: 'Abraham Lincoln Papers')
        end

        BerkeleyLibrary::TIND::Export::ExportFormat.each do |fmt|
          describe(fmt.value) do
            let(:format) { fmt.value.downcase }
            let(:expected_path) { "abraham-lincoln-papers.#{format}" }

            after do
              FileUtils.rm_f(expected_path)
            end

            it "downloads #{fmt}" do
              page.choose("export_format_#{format}")
              page.click_button('Download Metadata')

              # Wait for "Your download should start" to appear
              expect(page).to have_content('Your download should start momentarily', wait: 10)

              # TODO: Is it always downloaded to the project root?
              expect(File.exist?(expected_path)).to eq(true)
            end
          end
        end
      end
    end
  end
end
