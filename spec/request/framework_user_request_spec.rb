require 'forms_helper'

describe :forms_proxy_borrower_admin, type: :request do
  context 'specs with hardcoded admin' do
    before(:each) do
      # First create a DSP Rep and assignment
      @user = FrameworkUsers.create(id: 1, lcasid: 112_233, name: 'John Doe', role: 'Admin')
      @role = Role.create(id: 1, role: 'proxyborrow_admin')
      @assignment = Assignment.create(framework_users_id: 1, role_id: 1)

      # TODO: make this work
      calnet_yml_file = 'spec/data/calnet/5551212.yml'
      auth_hash = YAML.load_file(calnet_yml_file).merge(uid: FrameworkUsers.hardcoded_admin_uids[0])
      mock_omniauth_login(auth_hash)

      # # These functions require admin privledges:
      # admin_user = User.new(uid: '1707532')
      # allow_any_instance_of(ProxyBorrowerAdminController).to receive(:current_user).and_return(admin_user)
    end

    it 'removes an admin user' do
      delete "/forms/proxy-borrower/delete_admin/#{@user.id}"
      expect(response.body).to have_content('Removed John Doe from administrator list')
      expect(FrameworkUsers.count).to eq(0)
    end

    it 'adds an admin user' do
      post "/forms/proxy-borrower/add_admin", params: {lcasid: '12345678', name: 'Jane Doe'}
      expect(response.status).to eq('200')
      expect(response.body).to have_content('Jane Doe')
      expect(FrameworkUsers.find_by(lcasid: '12345678')).not_to be_nil
    end
  end
end
