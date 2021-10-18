require 'rails_helper'

describe User do
  attr_reader :student_id
  attr_reader :student_record
  attr_reader :employee_id
  attr_reader :employee_record
  attr_reader :cs_id
  attr_reader :cs_record
  attr_reader :ucpath_id
  attr_reader :ucpath_record
  attr_reader :uid

  before(:each) do
    allow(Alma::User).to receive(:find).and_raise(Error::PatronNotFoundError)
  end

  describe :from_omniauth do
    it 'rejects invalid providers' do
      auth = { 'provider' => 'not calnet' }
      expect { User.from_omniauth(auth) }.to raise_error(Error::InvalidAuthProviderError)
    end

    it 'populates a User object' do
      framework_admin_ldap = 'cn=edu:berkeley:org:libr:framework:LIBR-framework-admins,ou=campus groups,dc=berkeley,dc=edu'
      auth = {
        'provider' => 'calnet',
        'extra' => {
          'berkeleyEduAffiliations' => 'expected affiliation',
          'departmentNumber' => 'expected dept. number',
          'displayName' => 'expected display name',
          'berkeleyEduOfficialEmail' => 'expected email',
          'employeeNumber' => 'expected employee ID',
          'givenName' => 'expected given name',
          'berkeleyEduStuID' => 'expected student ID',
          'surname' => 'expected surname',
          'berkeleyEduUCPathID' => 'expected UC Path ID',
          'uid' => 'expected UID',
          'berkeleyEduIsMemberOf' => framework_admin_ldap
        }
      }

      [true, false].each do |is_framework_admin|
        auth['extra']['berkeleyEduIsMemberOf'] = is_framework_admin ? framework_admin_ldap : ''
        user = User.from_omniauth(auth)
        expect(user.affiliations).to eq('expected affiliation')
        expect(user.department_number).to eq('expected dept. number')
        expect(user.display_name).to eq('expected display name')
        expect(user.email).to eq('expected email')
        expect(user.employee_id).to eq('expected employee ID')
        expect(user.given_name).to eq('expected given name')
        expect(user.student_id).to eq('expected student ID')
        expect(user.surname).to eq('expected surname')
        expect(user.ucpath_id).to eq('expected UC Path ID')
        expect(user.uid).to eq('expected UID')
        expect(user.framework_admin).to eq(is_framework_admin)
      end
    end
  end

  describe :authenticated? do
    it 'returns true if user has an ID' do
      user = User.new(uid: '12345')
      expect(user.authenticated?).to eq(true)
    end

    it 'returns false if user ID is nil' do
      user = User.new(uid: nil)
      expect(user.authenticated?).to eq(false)
    end
  end

end
