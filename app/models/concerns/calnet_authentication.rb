# Handles CalNet authentication and attribute validation for User
module CalnetAuthentication
  FRAMEWORK_ADMIN_GROUP = 'cn=edu:berkeley:org:libr:framework:LIBR-framework-admins,ou=campus groups,dc=berkeley,dc=edu'.freeze
  ALMA_ADMIN_GROUP = 'cn=edu:berkeley:org:libr:framework:alma-admins,ou=campus groups,dc=berkeley,dc=edu'.freeze

  # CalNet attribute mapping derived from configuration
  CALNET_ATTRS = Rails.application.config.calnet_attrs.freeze

  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods
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
      verify_calnet_attributes!(auth_extra)
      cal_groups = auth_extra['berkeleyEduIsMemberOf'] || []

      # NOTE: berkeleyEduCSID should be same as berkeleyEduStuID for students
      {
        affiliations: get_attribute_from_auth(auth_extra, :affiliations),
        cs_id: auth_extra['berkeleyEduCSID'], # Not included in CALNET_ATTRS because it's not used by any applications; Just keep it here.
        department_number: get_attribute_from_auth(auth_extra, :department_number),
        display_name: get_attribute_from_auth(auth_extra, :display_name),
        email: get_attribute_from_auth(auth_extra, :email),
        employee_id: get_attribute_from_auth(auth_extra, :employee_id),
        given_name: get_attribute_from_auth(auth_extra, :given_name),
        student_id: get_attribute_from_auth(auth_extra, :student_id),
        surname: get_attribute_from_auth(auth_extra, :surname),
        ucpath_id: get_attribute_from_auth(auth_extra, :ucpath_id),
        uid: auth_extra['uid'] || auth['uid'],
        framework_admin: cal_groups.include?(FRAMEWORK_ADMIN_GROUP),
        alma_admin: cal_groups.include?(ALMA_ADMIN_GROUP)
      }
    end
    # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

    # Verifies that auth_extra contains the required email CalNet attribute
    # For array attributes, at least one value in the array must be present in auth_extra
    # Raise [Error::CalnetError] if the email attribute is missing
    def verify_calnet_attributes!(auth_extra)
      email_attrs = CALNET_ATTRS[:email]
      return if present_in_auth_extra?(auth_extra, email_attrs)

      raise_missing_calnet_attribute_error(auth_extra, Array(email_attrs))
    end

    def raise_missing_calnet_attribute_error(auth_extra, missing)
      missing_attrs = "Expected CalNet attribute(s) not found (case-sensitive): #{missing.join(', ')}."
      actual_calnet_keys = auth_extra.keys.reject { |k| k.start_with?('duo') }.sort
      msg = "#{missing_attrs} The actual CalNet attributes: #{actual_calnet_keys.join(', ')}. The user is #{auth_extra['uid']}"
      Rails.logger.error(msg)
      raise Error::CalnetError, msg
    end

    def present_in_auth_extra?(auth_extra, attr)
      if attr.is_a?(Array)
        attr.any? { |a| auth_extra.key?(a) }
      else
        auth_extra.key?(attr)
      end
    end

    # Gets an attribute value from auth_extra, handling both string and array attribute names as defined in CALNET_ATTRS.
    # For array attribute names, it tries each name in order and returns the first match.
    # This is to handle situations where the same attribute may have different attribute names
    # (e.g. berkeleyEduAlternateID vs berkeleyEduAlternateId).
    # If attribute is a string, returns the value for that key
    def get_attribute_from_auth(auth_extra, attr_key)
      attrs = CALNET_ATTRS[attr_key]
      return auth_extra[attrs] unless attrs.is_a?(Array)

      attrs.find { |attr| auth_extra.key?(attr) }.then { |attr| attr && auth_extra[attr] }
    end
  end
end
