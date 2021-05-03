require 'capybara_helper'
require 'calnet_helper'
require 'roo'

def verify_row_geometry(ss_actual, ss_expected)
  row_and_col_attrs = %i[first_row first_column last_row last_column]

  row_and_col_attrs.each do |attr|
    expected = ss_expected.send(attr)
    actual = ss_actual.send(attr)
    expect(actual).to eq(expected), "Expected #{attr} to be #{expected}, but was #{actual}"
  end

  first_row, first_column, last_row, last_column = row_and_col_attrs.map { |attr| ss_expected.send(attr) }
  [first_column, first_row, last_column, last_row]
end

def verify_value(ss_actual, row, col, ss_expected)
  expected_value = ss_expected.cell(row, col)
  actual_value = ss_actual.cell(row, col)
  msg = -> { "Expected value at (#{[row, col].join(', ')}) to be #{expected_value.inspect}, but was #{actual_value.inspect}" }
  expect(actual_value).to eq(expected_value), msg
end
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
          search_id = 'DnF1ZXJ5VGhlbkZldGNoBQAAAAABsY'
          search_url = 'https://digicoll.lib.berkeley.edu/api/v1/search'
          search_params = { c: 'Abraham Lincoln Papers', format: 'xml' }
          search_params_with_search_id = search_params.merge(search_id: search_id)
          result_1 = File.read('spec/data/tind_download/tind-abraham-lincoln-1.xml')
          result_2 = File.read('spec/data/tind_download/tind-abraham-lincoln-2.xml')
          stub_request(:get, search_url).with(query: search_params).to_return(status: 200, body: result_1)
          stub_request(:get, search_url).with(query: search_params_with_search_id).to_return(status: 200, body: result_2)

          fill_in('collection_name', with: 'Abraham Lincoln Papers')
        end

        def verify_download(expected_path, actual_path, format:)
          return verify_csv(expected_path, actual_path) if format == UCBLIT::TIND::Export::ExportFormat::CSV

          verify_ods(expected_path, actual_path) if format == UCBLIT::TIND::Export::ExportFormat::ODS
        end

        def verify_ods(expected_path, actual_path)
          ss_expected = Roo::Spreadsheet.open(expected_path, file_warning: :warning)
          ss_actual = Roo::Spreadsheet.open(actual_path, file_warning: :warning)

          first_column, first_row, last_column, last_row = verify_row_geometry(ss_actual, ss_expected)

          aggregate_failures(:values) do
            (first_row..last_row).each do |row|
              (first_column..last_column).each do |col|
                verify_value(ss_actual, row, col, ss_expected)
              end
            end
          end
        end

        def verify_csv(expected_path, actual_path)
          actual = File.binread(actual_path)
          expected = File.binread(expected_path)
          expect(actual).to eq(expected)
        end

        UCBLIT::TIND::Export::ExportFormat.each do |fmt|
          it "downloads #{fmt}" do
            format = fmt.value.downcase

            page.choose("export_format_#{format}")
            page.click_button('Download Metadata')

            # Wait for "Your download should start" to appear
            expected_msg = 'Your download should start momentarily'
            expect(page).to have_selector('p', text: expected_msg, visible: true)

            # Wait for download
            expected_filename = "abraham-lincoln-papers.#{format}"
            downloaded_file_path = CapybaraHelper.wait_for_download(expected_filename, 3)

            # Check file contents
            expected_file_path = File.join('spec/data/tind_download', expected_filename)
            verify_download(expected_file_path, downloaded_file_path, format: fmt)
          end
        end
      end
    end
  end
end
