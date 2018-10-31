class User
  include ActiveModel::Model

  class << self
    # Returns a new user object from the given "omniauth.auth" hash. That's a
    # hash of all data returned by the auth provider (in our case, calnet).
    #
    # For a schema, see:
    #   https://github.com/omniauth/omniauth/wiki/Auth-Hash-Schema
    #
    # For sample data from Calnet, see:
    #   https://git.lib.berkeley.edu/lap/altmedia/issues/16#note_5549
    def from_omniauth(auth)
      raise Framework::Errors::InvalidAuthProviderError, auth["provider"] \
        if auth["provider"].to_sym != :calnet

      self.new(
        affiliations: auth["extra"]["berkeleyEduAffiliations"],
        department_number: auth["extra"]['departmentNumber'],
        display_name: auth["extra"]['displayName'],
        email: auth["extra"]["berkeleyEduOfficialEmail"],
        employee_id: auth["extra"]['employeeNumber'],
        given_name: auth["extra"]['givenName'],
        student_id: auth["extra"]["berkeleyEduStuID"] || auth["extra"]["berkeleyEduCSID"],
        surname: auth["extra"]["surname"],
        uid: auth["extra"]["uid"] || auth["uid"],
      )
    end

    def attribute_names
      [
        :affiliations,
        :department_number,
        :display_name,
        :email,
        :employee_id,
        :given_name,
        :student_id,
        :surname,
        :uid,
      ]
    end
  end

  attr_accessor *self.attribute_names

  def authenticated?
    not uid.nil?
  end

  def patron
    @patron ||= Patron.find(employee_id)
  end
end
