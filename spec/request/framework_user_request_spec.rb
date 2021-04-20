require 'forms_helper'

describe :forms_proxy_borrower_admin, type: :request do
  context 'specs with hardcoded admin' do
    before(:each) do
      # TODO: make this work
      calnet_yml_file = 'spec/data/calnet/5551212.yml'
      hardcoded_admin_id = FrameworkUsers.hardcoded_admin_uids[0]
      auth_hash = YAML.load_file(calnet_yml_file).merge('uid' => hardcoded_admin_id)
      auth_hash['extra'].merge!('uid' => hardcoded_admin_id)
      mock_omniauth_login(auth_hash)

      # # These functions require admin privledges:
      # admin_user = User.new(uid: '1707532')
      # allow_any_instance_of(ProxyBorrowerAdminController).to receive(:current_user).and_return(admin_user)
    end

    it 'removes an admin user' do
      # First, create the user (directly)
      user = FrameworkUsers.create(lcasid: 112_233, name: 'John Doe', role: 'Admin')
      Assignment.create(framework_users: user, role: Role.proxyborrow_admin)

      # Then, delete via the controller
      delete "/forms/proxy-borrower/delete_admin/#{user.id}"
      expect(response).to redirect_to(forms_proxy_borrower_admin_users_path)
      get(forms_proxy_borrower_admin_users_path)
      expect(response.body).to include('Removed John Doe from administrator list')
      expect(Assignment.count).to eq(0)
    end

    it 'adds an admin user' do
      post '/forms/proxy-borrower/add_admin', params: { lcasid: '12345678', name: 'Jane Doe' }

      expect(response).to redirect_to(forms_proxy_borrower_admin_users_path)
      get(forms_proxy_borrower_admin_users_path)

      expect(response.status).to eq(200)
      expect(response.body).to include('Jane Doe')

      created_user = FrameworkUsers.find_by(lcasid: '12345678')
      expect(created_user).not_to be_nil

      assignment = Assignment.find_by(framework_users_id: created_user.id, role_id: Role.proxyborrow_admin.id)
      expect(assignment).not_to be_nil
    end
  end
end
