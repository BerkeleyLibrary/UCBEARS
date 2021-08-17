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
  # rubocop:disable Metrics/AbcSize
  def validate_each(_model, _attrname, patron)
    raise Error::PatronNotFoundError unless patron.is_a?(Patron::Record)
    raise Error::ForbiddenError if affiliation_missing?(patron, options[:affiliations])
    raise Error::ForbiddenError if wrong_type?(patron, options[:types])
    raise Error::PatronNotEligibleError.new(nil, patron) if note_missing?(patron, options[:note])
    raise Error::PatronBlockedError if patron.blocks
  end
  # rubocop:enable Metrics/AbcSize

  private

  def affiliation_missing?(patron, affiliations)
    return if affiliations.blank?

    !affiliations.include?(patron.affiliation)
  end

  def wrong_type?(patron, types)
    return if types.blank?

    !types.include?(patron.type)
  end

  def note_missing?(patron, note_pattern)
    return unless note_pattern

    note_pattern = Regexp.new(note_pattern) if note_pattern.is_a?(String)
    patron.notes.none? { |n| n =~ note_pattern }
  end

end
