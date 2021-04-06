require 'rails_helper'

RSpec.describe 'Fines', type: :request do

  describe 'GET /index' do
    it 'returns http success' do
      get '/fines/index'
      expect(response).to have_http_status(:success)
    end
  end

end
