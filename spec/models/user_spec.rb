require 'rails_helper'

describe User do
  attr_reader :student_id
  attr_reader :student_record
  attr_reader :employee_id
  attr_reader :employee_record
  attr_reader :cs_id
  attr_reader :cs_record

  before(:each) do
    allow(Patron::Record).to receive(:find).and_raise(Error::PatronNotFoundError)

    @student_id = 123_456_789
    @student_record = Patron::Record.new(id: student_id, expiration_date: Patron::Record::MILLENNIUM_MAX_DATE)
    allow(Patron::Record).to receive(:find).with(student_id).and_return(student_record)

    @employee_id = 987_654_321
    @employee_record = Patron::Record.new(id: employee_id, expiration_date: Patron::Record::MILLENNIUM_MAX_DATE)
    allow(Patron::Record).to receive(:find).with(employee_id).and_return(employee_record)

    @cs_id = 246_813_579
    @cs_record = Patron::Record.new(id: cs_id, expiration_date: Patron::Record::MILLENNIUM_MAX_DATE)
    allow(Patron::Record).to receive(:find).with(cs_id).and_return(cs_record)
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

  describe :primary_patron_record do
    it 'returns a student record' do
      user = User.new(student_id: student_id)
      expect(user.primary_patron_record).to eq(student_record)
    end

    it 'returns an employee record' do
      user = User.new(employee_id: employee_id)
      expect(user.primary_patron_record).to eq(employee_record)
    end

    it 'prefers a student ID to an employee ID' do
      user = User.new(
        student_id: student_id,
        employee_id: employee_id
      )
      expect(Patron::Record).not_to receive(:find).with(employee_id)
      expect(user.primary_patron_record).to eq(student_record)
    end

    it 'prefers a student ID to a CSID' do
      user = User.new(
        student_id: student_id,
        cs_id: cs_id
      )
      expect(Patron::Record).not_to receive(:find).with(cs_id)
      expect(user.primary_patron_record).to eq(student_record)
    end

    it 'prefers a CSID to an employee ID' do
      user = User.new(
        cs_id: cs_id,
        employee_id: employee_id
      )
      expect(Patron::Record).not_to receive(:find).with(employee_id)
      expect(user.primary_patron_record).to eq(cs_record)
    end

    it 'returns CS record if student record expired' do
      user = User.new(student_id: student_id, cs_id: cs_id, employee_id: employee_id)
      expect(student_record).to receive(:expired?).and_return(true)
      expect(user.primary_patron_record).to eq(cs_record)
    end

    it 'falls back to an employee ID' do
      user = User.new(
        student_id: (1 + student_id),
        cs_id: (employee_id - 1),
        employee_id: employee_id
      )
      expect(user.primary_patron_record).to eq(employee_record)
    end

    it 'returns employee record if other records expired' do
      user = User.new(student_id: student_id, cs_id: cs_id, employee_id: employee_id)
      [student_record, cs_record].each do |record|
        expect(record).to receive(:expired?).and_return(true)
      end
      expect(user.primary_patron_record).to eq(employee_record)
    end

    it 'returns nil if no student or employee patron ID found' do
      user = User.new(
        student_id: (1 + student_id),
        employee_id: (1 + employee_id)
      )
      expect(user.primary_patron_record).to be_nil
    end

    it 'returns nil if no IDs set' do
      user = User.new
      expect(user.primary_patron_record).to be_nil
    end

    it 'returns nil if all records expired' do
      user = User.new(student_id: student_id, cs_id: cs_id, employee_id: employee_id)
      [student_record, cs_record, employee_record].each do |record|
        expect(record).to receive(:expired?).and_return(true)
      end
      expect(user.primary_patron_record).to be_nil
    end
  end
end
