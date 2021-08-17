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
    record.errors.add(attribute, :email, options.merge(value: value)) unless value =~ /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i
  end
end
