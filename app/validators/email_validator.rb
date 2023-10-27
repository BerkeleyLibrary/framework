# Validate that an attribute looks like a valid email address
#
# Usage:
#
#   class SomeModel
#     include ActiveModel::Model
#
#     attr_accessor :email
#
#     validates :email, email: true
#   end
#
# @see https://guides.rubyonrails.org/active_record_validations.html#custom-validators Custom Validators
class EmailValidator < ActiveModel::EachValidator
  # @note URI::MailTo::EMAIL_REGEXP considers "foo@bar" to be a valid email, which we don't want
  EMAIL_REGEXP = Regexp.compile(/\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i)

  def validate_each(record, attribute, value)
    record.errors.add(attribute, :email) unless value =~ EMAIL_REGEXP
  end
end
