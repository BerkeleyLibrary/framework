require 'forms_helper'

describe 'Proxy Borrower Forms', type: :request do
  include ActiveJob::TestHelper
  after { clear_enqueued_jobs }

  attr_reader :patron_id
  attr_reader :patron
  attr_reader :user

  let(:alma_api_key) { 'totally-fake-key' }

  context 'specs without admin privileges' do
    before do
      allow(Rails.application.config).to receive(:alma_api_key).and_return(alma_api_key)
      @patron_id = Alma::Type.sample_id_for(Alma::Type::FACULTY)
      @user = login_as_patron(patron_id)
      @patron = Alma::User.find(patron_id)
    end

    after do
      logout!
    end

    it 'Admin page redirects to main proxy borrower card page if user is non-admin', :non_admin do
      get forms_proxy_borrower_admin_path
      expect(response).to have_http_status :found
    end

    it 'Index page renders' do
      get proxy_borrower_forms_path
      expect(response).to have_http_status :ok
    end
  end

  context 'specs with created admin privileges' do
    before do
      allow(Rails.application.config).to receive(:alma_api_key).and_return(alma_api_key)

      # Need to create a request for search!!!
      @req = ProxyBorrowerRequests.new(
        faculty_name: 'Test Search User',
        department: 'ABCD',
        faculty_id: '12345',
        student_name: nil,
        student_dsp: nil,
        dsp_rep: nil,
        research_last: 'RLast',
        research_first: 'RFirst',
        research_middle: nil,
        date_term: Date.tomorrow,
        renewal: 0,
        status: nil
      )

      # make sure we have a fresh set of tables:
      Assignment.delete_all
      Role.delete_all
      FrameworkUsers.delete_all

      # Create a user:
      framework_user = FrameworkUsers.create(lcasid: '333333', name: 'John Doe', role: 'Admin')

      # Create an assignment:
      Assignment.create(framework_users: framework_user, role: Role.proxyborrow_admin)

      @patron_id = Alma::Type.sample_id_for(Alma::Type::FACULTY)
      @user = login_as_patron(patron_id)
      @patron = Alma::User.find(patron_id)

      admin_user = User.new(uid: '333333', affiliations: ['EMPLOYEE-TYPE-ACADEMIC'])
      allow_any_instance_of(ProxyBorrowerFormsController).to receive(:current_user).and_return(admin_user)
    end

    it 'Index contain disabled student links' do
      get proxy_borrower_forms_path
      expect(response.body).to include('<a href="/forms/proxy-borrower/dsp">Request Disabled Student</a>')
      expect(response).to have_http_status :ok
    end

    it 'Faculty Form renders for faculty members' do
      get forms_proxy_borrower_faculty_path
      expect(response).to have_http_status :ok
    end
  end
end
