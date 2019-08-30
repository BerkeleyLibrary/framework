# Represents a user in our system
#
# This is closely coupled to CalNet's user schema.
class User
  include ActiveModel::Model

  FRAMEWORK_ADMIN_GROUP = 'cn=edu:berkeley:org:libr:framework:LIBR-framework-admins,ou=campus groups,dc=berkeley,dc=edu'.freeze

  class << self
    # Returns a new user object from the given "omniauth.auth" hash. That's a
    # hash of all data returned by the auth provider (in our case, calnet).
    #
    # @see https://github.com/omniauth/omniauth/wiki/Auth-Hash-Schema OmniAuth Schema
    # @see https://git.lib.berkeley.edu/lap/altmedia/issues/16#note_5549 Sample Calnet Response
    # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    def from_omniauth(auth)
      raise Error::InvalidAuthProviderError, auth['provider'] \
        if auth['provider'].to_sym != :calnet

      # Note: berkeleyEduCSID should be same as berkeleyEduStuID for students
      new(
        affiliations: auth['extra']['berkeleyEduAffiliations'],
        cs_id: auth['extra']['berkeleyEduCSID'],
        department_number: auth['extra']['departmentNumber'],
        display_name: auth['extra']['displayName'],
        email: auth['extra']['berkeleyEduOfficialEmail'],
        employee_id: auth['extra']['employeeNumber'],
        given_name: auth['extra']['givenName'],
        student_id: auth['extra']['berkeleyEduStuID'],
        surname: auth['extra']['surname'],
        uid: auth['extra']['uid'] || auth['uid'],
        framework_admin: auth['extra']['berkeleyEduIsMemberOf'].include?(FRAMEWORK_ADMIN_GROUP)
      )
    end
    # rubocop:enable Metrics/AbcSize, Metrics/MethodLength
  end

  # @return [String]
  attr_accessor :affiliations

  # "Unique identifier from Campus Solutions (Emplid)" per CalNet docs.
  # For students, should be the same value as berkeleyEduStuID.
  #
  # @see https://calnetweb.berkeley.edu/calnet-technologists/ldap-directory-service/ldap-simplification-and-standardization CalNet docs
  # @return [String]
  attr_accessor :cs_id

  # @return [String]
  attr_accessor :department_number

  # @return [String]
  attr_accessor :display_name

  # @return [String]
  attr_accessor :email

  # @return [String]
  attr_accessor :employee_id

  # @return [String]
  attr_accessor :given_name

  # @return [String]
  attr_accessor :student_id

  # @return [String]
  attr_accessor :surname

  # @return [String]
  attr_accessor :uid

  # @return [Boolean]
  attr_accessor :framework_admin

  # Whether the user was authenticated
  #
  # The user object is PORO, and we always want to be able to return it even in
  # cases where the current (anonymous) user hasn't authenticated. This method
  # is provided as a convenience to tell if the user's actually been auth'd.
  #
  # @return [Boolean]
  def authenticated?
    !uid.nil?
  end

  def primary_patron_record
    @primary_patron_record ||= find_primary_record
  end

  private

  # The user's employee patron record
  # @return [Patron::Record, nil]
  def employee_patron_record
    @employee_patron_record ||= Patron::Record.find_if_exists(employee_id)
  end

  # The user's student patron record (if they have a student ID)
  # @return [Patron::Record, nil]
  def student_patron_record
    @student_patron_record ||= Patron::Record.find_if_exists(student_id)
  end

  # The user's Campus Solutions patron record (if they have a Campus Solutions ID)
  # @return [Patron::Record, nil]
  def csid_patron_record
    @csid_patron_record ||= Patron::Record.find_if_exists(cs_id)
  end

  # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity
  def find_primary_record
    return student_patron_record if student_patron_record && !student_patron_record.expired?
    return csid_patron_record if csid_patron_record && !csid_patron_record.expired?

    employee_patron_record if employee_patron_record && !employee_patron_record.expired?
  end
  # rubocop:enable Metrics/AbcSize, Metrics/CyclomaticComplexity
end
