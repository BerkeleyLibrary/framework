require 'rails_helper'
require 'calnet_helper'
require 'support/uploaded_file_context'

RSpec.describe TindValidatorController, type: :request do
  # include_context('uploaded file')
  # let(:input_file_path) { 'spec/data/tind_validator/fonoroff_with_errors.csv' }
  # let(:input_file_basename) { File.basename(input_file_path) }

  context 'specs for unauthorized user' do
    before do
      logout!
    end

    context 'index' do
      it 'GET requires login' do
        get tind_spread_validator_path
        expect(response).to have_http_status :unauthorized
      end
    end
  end

  describe 'authenticated user' do
    before do
      # login_as_patron(Alma::ALMA_ADMIN_ID)
      @current_user = login_as_patron(Alma::ALMA_ADMIN_ID)
      @current_user.email = 'notreal@nowhere.com'

      # And pass @user to the controller as the current_user:
      allow_any_instance_of(TindValidatorController).to receive(:current_user).and_return(@current_user)
    end

    context 'index' do
      it 'GETS a valid user' do
        get(tind_spread_validator_path)
        expect(@current_user.alma_admin?).to be(true)
      end

      it 'GETS a form' do
        get(tind_spread_validator_path)
        expect(response.body).to include('Tind Spreadsheet Validator')
      end
    end

    context 'Successful submission' do
      before do
        upload_file = Rack::Test::UploadedFile.new(Rails.root.join('spec', 'data', 'tind_validator', 'fonoroff_with_errors.csv'), 'text/csv')
        @params = {
          '980__a': 'Librettos',
          '982__a': 'Italian Librettos',
          '982__b': 'Italian Librettos',
          '982__p': 'Some larger project',
          '540__a': 'some restriction text',
          '336__a': 'Image',
          '852__c': 'The Bancroft Library',
          '902__n': 'DMZ',
          input_file: upload_file,
          '991__a': 'Resticted2Admin'
        }
      end

      it 'returns result page' do
        post('/tind-spread-validator', params: @params)
        expect(response.body).to include('Your Tind MARC batch load has been submitted')
      end
    end

    context 'failed submission' do
      before do
        upload_file = Rack::Test::UploadedFile.new(Rails.root.join('spec', 'data', 'tind_validator', 'fonoroff_with_errors.csv'), 'plain/text')
        @params = {
          '980__a': 'Librettos',
          '982__a': 'Italian Librettos',
          '982__b': 'Italian Librettos',
          '982__p': 'Some larger project',
          '540__a': 'some restriction text',
          '336__a': 'Image',
          '852__c': 'The Bancroft Library',
          '902__n': 'DMZ',
          input_file: upload_file,
          '991__a': 'Resticted2Admin'
        }
      end

      it 'returns errors' do
        post('/tind-spread-validator', params: @params)
        expect(flash[:danger]).to include('Input file must be a CSV or XLSX file')
      end
    end
  end
end
