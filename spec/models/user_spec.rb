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

  before do
    allow(Alma::User).to receive(:find).and_raise(Error::PatronNotFoundError)
  end

  describe :from_omniauth do
    it 'rejects invalid providers' do
      auth = { 'provider' => 'not calnet' }
      expect { User.from_omniauth(auth) }.to raise_error(Error::InvalidAuthProviderError)
    end

    it 'rejects calnet when a required schema attribute is missing or renamed' do
      auth = {
        'provider' => 'calnet',
        'extra' => {
          'berkeleyEduAffiliations' => 'expected affiliation',
          'berkeleyEduCSID' => 'expected cs id',
          'berkeleyEduIsMemberOf' => [],
          'berkeleyEduUCPathID' => 'expected UC Path ID',
          'berkeleyEduAlternatid' => 'expected email', # intentionally wrong case to simulate wrong attribute
          'departmentNumber' => 'expected dept. number',
          'displayName' => 'expected display name',
          'employeeNumber' => 'expected employee ID',
          'givenName' => 'expected given name',
          'surname' => 'expected surname',
          'uid' => 'expected UID'
        }
      }

      missing = %w[berkeleyEduAlternateID berkeleyEduAlternateId]
      actual = %w[berkeleyEduAffiliations berkeleyEduAlternatid berkeleyEduCSID berkeleyEduIsMemberOf berkeleyEduUCPathID departmentNumber
                  displayName employeeNumber givenName surname uid]
      # rubocop:disable Layout/LineLength
      msg = "Expected Calnet attribute(s) not found (case-sensitive): #{missing.join(', ')}. The actual CalNet attributes: #{actual.join(', ')}. The user is expected display name"
      # rubocop:enable Layout/LineLength
      expect { User.from_omniauth(auth) }.to raise_error(Error::CalnetError, msg)
    end

    it 'populates a User object' do
      framework_admin_ldap = 'cn=edu:berkeley:org:libr:framework:LIBR-framework-admins,ou=campus groups,dc=berkeley,dc=edu'
      auth = {
        'provider' => 'calnet',
        'extra' => {
          'berkeleyEduAffiliations' => 'expected affiliation',
          'departmentNumber' => 'expected dept. number',
          'displayName' => 'expected display name',
          'berkeleyEduAlternateID' => 'expected email',
          'employeeNumber' => 'expected employee ID',
          'givenName' => 'expected given name',
          'berkeleyEduCSID' => 'expected cs id',
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
        expect(user.student_id).to eq(nil)
        expect(user.surname).to eq('expected surname')
        expect(user.ucpath_id).to eq('expected UC Path ID')
        expect(user.uid).to eq('expected UID')
        expect(user.framework_admin).to eq(is_framework_admin)
      end
    end

    it 'handles a user without CalGroups' do
      auth = {
        'provider' => 'calnet',
        'extra' => {
          'berkeleyEduAffiliations' => 'expected affiliation',
          'departmentNumber' => 'expected dept. number',
          'displayName' => 'expected display name',
          'berkeleyEduAlternateID' => 'expected email',
          'employeeNumber' => 'expected employee ID',
          'givenName' => 'expected given name',
          'berkeleyEduCSID' => 'expected cs id',
          'surname' => 'expected surname',
          'berkeleyEduUCPathID' => 'expected UC Path ID',
          'uid' => 'expected UID'
        }
      }

      user = User.from_omniauth(auth)
      expect(user.affiliations).to eq('expected affiliation')
      expect(user.department_number).to eq('expected dept. number')
      expect(user.display_name).to eq('expected display name')
      expect(user.email).to eq('expected email')
      expect(user.employee_id).to eq('expected employee ID')
      expect(user.given_name).to eq('expected given name')
      expect(user.student_id).to eq(nil)
      expect(user.surname).to eq('expected surname')
      expect(user.ucpath_id).to eq('expected UC Path ID')
      expect(user.uid).to eq('expected UID')
      expect(user.framework_admin).to eq(false)
      expect(user.alma_admin).to eq(false)
    end

    it 'handles a user with old style email attribute' do
      auth = {
        'provider' => 'calnet',
        'extra' => {
          'berkeleyEduAffiliations' => 'expected affiliation',
          'departmentNumber' => 'expected dept. number',
          'displayName' => 'expected display name',
          'berkeleyEduAlternateId' => 'expected email',
          'employeeNumber' => 'expected employee ID',
          'givenName' => 'expected given name',
          'berkeleyEduStuID' => 'expected student ID',
          'surname' => 'expected surname',
          'berkeleyEduUCPathID' => 'expected UC Path ID',
          'berkeleyEduCSID' => 'expected cs id',
          'uid' => 'expected UID'
        }
      }

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
      expect(user.framework_admin).to eq(false)
      expect(user.alma_admin).to eq(false)
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

  describe :verify_calnet_attributes! do
    it 'allows employee-affiliated users without berkeleyEduStuID' do
      auth_extra = {
        'berkeleyEduAffiliations' => ['EMPLOYEE-TYPE-ACADEMIC'],
        'berkeleyEduCSID' => 'cs123',
        'berkeleyEduIsMemberOf' => [],
        'berkeleyEduUCPathID' => 'ucpath456',
        'berkeleyEduAlternateID' => 'email@berkeley.edu',
        'departmentNumber' => 'dept1',
        'displayName' => 'Test Faculty',
        'employeeNumber' => 'emp789',
        'givenName' => 'Test',
        'surname' => 'Faculty',
        'uid' => 'faculty1'
      }

      expect { User.from_omniauth({ 'provider' => 'calnet', 'extra' => auth_extra }) }.not_to raise_error
    end

    it 'allows student-affiliated users without employeeNumber and berkeleyEduUCPathID' do
      auth_extra = {
        'berkeleyEduAffiliations' => ['STUDENT-TYPE-REGISTERED'],
        'berkeleyEduCSID' => 'cs123',
        'berkeleyEduIsMemberOf' => [],
        'berkeleyEduStuID' => 'stu456',
        'berkeleyEduAlternateID' => 'email@berkeley.edu',
        'departmentNumber' => 'dept1',
        'displayName' => 'Test Student',
        'givenName' => 'Test',
        'surname' => 'Student',
        'uid' => 'student1'
      }

      expect { User.from_omniauth({ 'provider' => 'calnet', 'extra' => auth_extra }) }.not_to raise_error
    end

    it 'rejects student-affiliated users if berkeleyEduStuID is missing' do
      auth_extra = {
        'berkeleyEduAffiliations' => ['STUDENT-TYPE-REGISTERED'],
        'berkeleyEduCSID' => 'cs123',
        'berkeleyEduIsMemberOf' => [],
        'berkeleyEduAlternateID' => 'email@berkeley.edu',
        'departmentNumber' => 'dept1',
        'displayName' => 'Test Student',
        'givenName' => 'Test',
        'surname' => 'Student',
        'uid' => 'student1'
      }

      expect { User.from_omniauth({ 'provider' => 'calnet', 'extra' => auth_extra }) }.to raise_error(Error::CalnetError)
    end

    it 'rejects employee-affiliated users if employeeNumber is missing' do
      auth_extra = {
        'berkeleyEduAffiliations' => ['EMPLOYEE-TYPE-STAFF'],
        'berkeleyEduCSID' => 'cs123',
        'berkeleyEduIsMemberOf' => [],
        'berkeleyEduUCPathID' => 'ucpath456',
        'berkeleyEduAlternateID' => 'email@berkeley.edu',
        'departmentNumber' => 'dept1',
        'displayName' => 'Test Staff',
        'givenName' => 'Test',
        'surname' => 'Staff',
        'uid' => 'staff1'
      }

      expect { User.from_omniauth({ 'provider' => 'calnet', 'extra' => auth_extra }) }.to raise_error(Error::CalnetError)
    end
  end

end
