require 'calnet_helper'

describe HomeController, type: :request do
  describe :health do
    it 'returns OK for a successful patron lookup' do
      patron = Alma::User.new

      expect(Alma::User).to receive(:find).with(Health::Check::TEST_PATRON_ID).and_return(patron)
      get health_path
      expect(response).to have_http_status(:ok)
      expected_body = {
        'status' => 'pass',
        'details' => {
          'patron_api:find' => {
            'status' => 'pass'
          }
        }
      }
      expect(JSON.parse(response.body)).to eq(expected_body)
    end

    it 'returns 429 Too Many Requests for a failure' do
      expect(Alma::User).to receive(:find).and_raise('Something went wrong')
      get health_path
      expect(response).to have_http_status(:too_many_requests)
      expected_body = {
        'status' => 'warn',
        'details' => {
          'patron_api:find' => {
            'status' => 'warn',
            'output' => 'RuntimeError'
          }
        }
      }
      expect(JSON.parse(response.body)).to eq(expected_body)
    end
  end

  RSpec.shared_examples 'allow admin' do |page:|

    before do
      @name = page.to_s
    end

    it "allows a framework admin page - #{name}" do
      with_patron_login(Alma::FRAMEWORK_ADMIN_ID) do
        get admin_path if @name == 'admin' # TODO : figure out to use block
        get framework_admin_path if @name == 'framework_admin'
        expect(response).to have_http_status(:ok)
      end
    end

    it "disallows a non-framework admin page - #{name}" do
      patron_id = Alma::Type.sample_id_for(Alma::Type::VISITING_SCHOLAR)
      with_patron_login(patron_id) do |user|
        expect(user.framework_admin).to be_falsey # just to be sure
        get admin_path if @name == 'admin'
        get framework_admin_path if @name == 'framework_admin'
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe :admin do
    it_behaves_like('allow admin', page: 'admin')
  end

end
