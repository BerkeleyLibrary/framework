require 'forms_helper'

describe :forms_proxy_borrower_admin, type: :request do
  let(:admin_role) { Role.proxyborrow_admin }

  before do
    mock_login(CalnetHelper::TEST_UID)
  end

  it 'removes an admin user' do
    user = FrameworkUsers.create(lcasid: 112_233, name: 'John Doe', role: 'Admin')
    Assignment.create(framework_users: user, role: admin_role)

    delete "/forms/proxy-borrower/delete_admin/#{user.id}"

    expect(response).to redirect_to(forms_proxy_borrower_admin_users_path)

    get forms_proxy_borrower_admin_users_path

    expect(response.body).to include('Removed John Doe from administrator list')
    expect(Assignment.count).to eq(0)
  end

  it 'adds an admin user' do
    post '/forms/proxy-borrower/add_admin',
         params: { lcasid: '12345678', name: 'Jane Doe' }

    expect(response).to redirect_to(forms_proxy_borrower_admin_users_path)

    get forms_proxy_borrower_admin_users_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include('Jane Doe')

    created_user = FrameworkUsers.find_by(lcasid: '12345678')

    expect(created_user).not_to be_nil
    expect(
      Assignment.find_by(framework_users: created_user, role: admin_role)
    ).not_to be_nil
  end
end
