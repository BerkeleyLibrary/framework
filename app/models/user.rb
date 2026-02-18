# Represents a user in our system
#
# This is closely coupled to CalNet's user schema.
class User
  include ActiveModel::Model

  FRAMEWORK_ADMIN_GROUP = 'cn=edu:berkeley:org:libr:framework:LIBR-framework-admins,ou=campus groups,dc=berkeley,dc=edu'.freeze
  ALMA_ADMIN_GROUP = 'cn=edu:berkeley:org:libr:framework:alma-admins,ou=campus groups,dc=berkeley,dc=edu'.freeze

  class << self
    # Returns a new user object from the given "omniauth.auth" hash. That's a
    # hash of all data returned by the auth provider (in our case, calnet).
    #
    # @see https://github.com/omniauth/omniauth/wiki/Auth-Hash-Schema OmniAuth Schema
    # @see https://git.lib.berkeley.edu/lap/altmedia/issues/16#note_5549 Sample Calnet Response
    # @see https://calnetweb.berkeley.edu/calnet-technologists/ldap-directory-service/how-ldap-organized/people-ou/people-attribute-schema CalNet LDAP
    def from_omniauth(auth)
      raise Error::InvalidAuthProviderError, auth['provider'] \
        if auth['provider'].to_sym != :calnet

      new(**auth_params_from(auth))
    end

    private

    # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    def auth_params_from(auth)
      auth_extra = auth['extra']
      cal_groups = auth_extra['berkeleyEduIsMemberOf'] || []

      # NOTE: berkeleyEduCSID should be same as berkeleyEduStuID for students
      {
        affiliations: auth_extra['berkeleyEduAffiliations'],
        cs_id: auth_extra['berkeleyEduCSID'],
        department_number: auth_extra['departmentNumber'],
        display_name: auth_extra['displayName'],
        email: auth_extra['berkeleyEduAlternateID'] || auth_extra['berkeleyEduAlternateId'],
        employee_id: auth_extra['employeeNumber'],
        given_name: auth_extra['givenName'],
        student_id: auth_extra['berkeleyEduStuID'],
        surname: auth_extra['surname'],
        ucpath_id: auth_extra['berkeleyEduUCPathID'],
        uid: auth_extra['uid'] || auth['uid'],
        framework_admin: cal_groups.include?(FRAMEWORK_ADMIN_GROUP),
        alma_admin: cal_groups.include?(ALMA_ADMIN_GROUP)
      }
    end
    # rubocop:enable Metrics/AbcSize, Metrics/MethodLength
  end

  # Affiliations per CalNet (attribute `berkeleyEduAffiliations` e.g.
  # `EMPLOYEE-TYPE-FACULTY`, `STUDENT-TYPE-REGISTERED`).
  #
  # Not to be confused with {Patron::Record#affiliation}, which returns
  # the patron affiliation according to the Millennium patron record
  # `PCODE1` value.
  #
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
  attr_accessor :ucpath_id

  # @return [String]
  attr_accessor :uid

  # @return [Boolean]
  attr_accessor :framework_admin
  alias framework_admin? framework_admin

  # @return [Boolean]
  attr_accessor :alma_admin
  alias alma_admin? alma_admin

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

  # TODO: Unify this, faculty/staff checks, framework/alma admin checks
  #       (and improve the design)
  def role?(role)
    # First check if user is a hardcoded admin
    return true if FrameworkUsers.hardcoded_admin?(uid)

    # If user is not, then check if the user was added to the DB as an admin:
    user = FrameworkUsers.find_by(lcasid: uid)
    return false unless user

    user.assignments.exists?(role:)
  end

  def ucb_faculty?
    affiliations&.include?('EMPLOYEE-TYPE-ACADEMIC')
  end

  def ucb_staff?
    affiliations&.include?('EMPLOYEE-TYPE-STAFF')
  end

  private

  # @return [Alma::User, nil]
  def uid_patron_record
    @uid_patron_record ||= Alma::User.find_if_active(uid)
  end

  def find_primary_record
    uid_patron_record
  end
end
