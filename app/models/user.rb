# Represents a user in our system
#
# This is closely coupled to CalNet's user schema.
class User
  include ActiveModel::Model

  class << self
    # Returns a new user object from the given "omniauth.auth" hash. That's a
    # hash of all data returned by the auth provider (in our case, calnet).
    #
    # @see https://github.com/omniauth/omniauth/wiki/Auth-Hash-Schema OmniAuth Schema
    # @see https://git.lib.berkeley.edu/lap/altmedia/issues/16#note_5549 Sample Calnet Response
    def from_omniauth(auth)
      raise Error::InvalidAuthProviderError, auth["provider"] \
        if auth["provider"].to_sym != :calnet

      self.new(
        affiliations: auth["extra"]["berkeleyEduAffiliations"],
        department_number: auth["extra"]['departmentNumber'],
        display_name: auth["extra"]['displayName'],
        email: auth["extra"]["berkeleyEduOfficialEmail"],
        employee_id: auth["extra"]['employeeNumber'],
        given_name: auth["extra"]['givenName'],
        student_id: auth["extra"]["berkeleyEduStuID"],
        surname: auth["extra"]["surname"],
        uid: auth["extra"]["uid"] || auth["uid"],
        framework_admin: auth["extra"]["berkeleyEduIsMemberOf"].include?('cn=edu:berkeley:org:libr:framework:LIBR-framework-admins,ou=campus groups,dc=berkeley,dc=edu'),
      )
    end
  end

  # @return [String]
  attr_accessor :affiliations

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
    not uid.nil?
  end

  # The user's employee patron record
  # @return [Patron::Record, nil]
  def employee_patron_record
    @employee_patron_record ||= Patron::Record.find(employee_id) if self.employee_id
  end

  # The user's student patron record (if they have a student ID)
  # @return [Patron::Record, nil]
  def student_patron_record
    @student_patron_record ||= Patron::Record.find(student_id) if self.student_id
  end
end
