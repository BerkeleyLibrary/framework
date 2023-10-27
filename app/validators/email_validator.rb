require 'uri'

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
  def validate_each(record, attribute, value)
    record.errors.add(attribute, :email) unless value =~ URI::MailTo::EMAIL_REGEXP
  end
end
