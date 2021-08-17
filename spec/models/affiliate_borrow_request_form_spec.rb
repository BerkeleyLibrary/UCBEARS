require 'rails_helper'

describe AffiliateBorrowRequestForm do
  it 'validates the form' do
    tests = [
      {
        valid: false,
        attributes: {},
        errors: {
          department_head_email: ["can't be blank", 'is not a valid email address'],
          department_name: ["can't be blank"],
          employee_email: ["can't be blank", 'is not a valid email address'],
          employee_id: ["can't be blank"],
          employee_name: ["can't be blank"],
          employee_personal_email: ["can't be blank", 'is not a valid email address'],
          employee_phone: ["can't be blank"],
          employee_address: ["can't be blank"]
        }
      },
      {
        valid: false,
        attributes: {
          department_head_email: 'not an email',
          department_name: '',
          employee_email: 'not an email',
          employee_id: '',
          employee_name: '',
          employee_personal_email: 'not an email',
          employee_phone: '',
          employee_address: ''
        },
        errors: {
          department_head_email: ['is not a valid email address'],
          department_name: ["can't be blank"],
          employee_email: ['is not a valid email address'],
          employee_id: ["can't be blank"],
          employee_name: ["can't be blank"],
          employee_personal_email: ['is not a valid email address'],
          employee_phone: ["can't be blank"],
          employee_address: ["can't be blank"]
        }
      },
      {
        valid: true,
        attributes: {
          department_head_email: 'email@mail.com',
          department_name: 'not blank',
          employee_email: 'email@mail.com',
          employee_id: '12345',
          employee_name: 'not blank',
          employee_personal_email: 'email@mail.com',
          employee_phone: 'not blank',
          employee_address: 'not blank'
        },
        errors: {
          department_head_email: [],
          department_name: [],
          employee_email: [],
          employee_id: [],
          employee_name: [],
          employee_personal_email: [],
          employee_phone: [],
          employee_address: []
        }
      }
    ]
    tests.each do |attributes:, errors:, valid:|
      form = AffiliateBorrowRequestForm.new(attributes)
      expect(form.valid?).to eq(valid)
      next if valid

      errors.each do |attr_name, attr_errs|
        expect(form.errors[attr_name]).to eq(attr_errs)
      end

      expect { form.submit! }.to raise_error(ActiveModel::ValidationError)
    end
  end

  it 'sends the email' do
    form = AffiliateBorrowRequestForm.new(
      department_head_email: 'jeff@wilco.com',
      department_name: "Beat Keepin'",
      employee_email: 'glenn@wilco.com',
      employee_id: '12345',
      employee_name: 'Glenn Kotche',
      employee_personal_email: 'glenn@gmail.com',
      employee_phone: '1(773)009-4526',
      employee_address: '123 North St, Berkeley, CA 94707'
    )

    expect { form.submit! }.to(change { ActionMailer::Base.deliveries.count }.by(1))
    last_email = ActionMailer::Base.deliveries.last
    expect(last_email.subject).to eq('UC Berkeley Borrowing Card Requested')
    expect(last_email.to).to include('jeff@wilco.com')
  end

  describe :model_name do
    it 'has a human name' do
      expect(AffiliateBorrowRequestForm.model_name.human).to eq('UCB Library Resources for Select Affiliate Staff')
    end
  end
end
