require 'rails_helper'

describe StackRequest do

  it 'validates the form' do
    tests = [
      {
        valid: false,
        attributes: {},
        errors: {
          name: ["can't be blank"],
          email: ["can't be blank", 'is not a valid email address']
        }
      },
      {
        valid: false,
        attributes: {
          name: 'John Doe'
        },
        errors: {
          email: ["can't be blank", 'is not a valid email address']
        }
      },
      {
        valid: false,
        attributes: {
          name: 'John Doe',
          email: 'jdoebademail'
        },
        errors: {
          email: ['is not a valid email address']
        }
      },
      {
        valid: true,
        attributes: {
          name: 'Jane Doe',
          email: 'jdoe@bereley.edu'
        },
        errors: {}
      }
    ]
    tests.each do |attributes:, errors:, valid:|
      form = StackRequest.new(attributes)
      expect(form.valid?).to eq valid
      next if valid

      errors.each do |attr_name, attr_errs|
        expect(form.errors[attr_name]).to eq(attr_errs)
      end
    end
  end

end
