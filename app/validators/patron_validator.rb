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
  def validate_each(_model, _attrname, patron)
    raise Error::PatronNotFoundError unless patron.is_a?(Alma::User)
    raise Error::ForbiddenError if wrong_type?(patron, options[:types])
    raise Error::PatronNotEligibleError.new(nil, patron) if note_missing?(patron, options[:note])
    raise Error::PatronBlockedError if patron.blocks
  end

  private

  def wrong_type?(patron, types)
    return false if types.blank?

    types.exclude?(patron.type)
  end

  def note_missing?(patron, note_pattern)
    return false unless note_pattern

    note_pattern = Regexp.new(note_pattern) if note_pattern.is_a?(String)
    # TODO: Clean up use of notes_array vs. find_note
    patron.notes_array.none? { |n| n =~ note_pattern }
  end

end
