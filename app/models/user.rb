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
        unless auth["provider"] == "calnet"

      self.new(
        display_name: auth["extra"]['displayName'],
        employee_id: auth["extra"]['employeeNumber'],
        uid: auth["uid"],
      )
    end

    def attribute_names
      [:uid, :display_name, :employee_id]
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
