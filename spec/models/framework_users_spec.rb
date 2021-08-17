require 'rails_helper'

describe FrameworkUsers do
  it 'validates a Framework User object' do
    tests = [
      {
        valid: false,
        attributes: {},
        errors: {
          lcasid: ["can't be blank"],
          name: ["can't be blank"],
          role: ["can't be blank"]
        }
      },
      {
        valid: true,
        attributes: {
          lcasid: '1234567',
          name: 'Darth Vader',
          role: 'Admin'
        },
        errors: {
          dsp_rep_name: []
        }
      }
    ]
    tests.each do |attributes:, errors:, valid:|
      form = FrameworkUsers.new(attributes)
      expect(form.valid?).to eq(valid)
      next if valid

      errors.each do |attr_name, attr_errs|
        expect(form.errors[attr_name]).to eq(attr_errs)
      end
    end
  end
end
