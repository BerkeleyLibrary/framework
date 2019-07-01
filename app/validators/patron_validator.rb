# Validates the Patron record
#
# Usage:
#
#   class SomeModel
#     include ActiveModel::Model
#
#     validates :patron, patron: { note: /some-pattern/ }
#   end
#
# @see https://guides.rubyonrails.org/active_record_validations.html#custom-validators Custom Validators
class PatronValidator < ActiveModel::EachValidator
  def validate_each(model, attrname, patron)
    affiliations = options[:affiliations] || []
    note_pattern = options[:note]
    types = options[:types] || []

    if not patron.kind_of?(Patron::Record)
      raise Error::PatronNotFoundError
    end

    if affiliations.any? and not affiliations.include?(patron.affiliation)
      raise Error::ForbiddenError
    end

    if types.any? and not types.include?(patron.type)
      raise Error::ForbiddenError
    end

    if note_pattern and patron.notes.none?(note_pattern)
      raise Error::PatronNotEligibleError.new(nil, patron)
    end

    if patron.blocks
      raise Error::PatronBlockedError
    end
  end
end
