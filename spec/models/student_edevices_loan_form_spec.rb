require 'rails_helper'

describe StudentEdevicesLoanForm do
  allowed_patron_types = [
    Patron::Type::UNDERGRAD,
    Patron::Type::UNDERGRAD_SLE,
    Patron::Type::GRAD_STUDENT
  ]

  forbidden_patron_types = Patron::Type.all.reject { |t| allowed_patron_types.include?(t) }

  describe :submit do
    attr_reader :patron
    attr_reader :form

    before(:each) do
      @patron = Patron::Record.new(
        id: 12_345,
        email: 'jdoe@berkeley.test',
        affiliation: Patron::Affiliation::UC_BERKELEY,
        type: allowed_patron_types.first
      )
      @form = StudentEdevicesLoanForm.new(
        patron: patron,
        given_name: 'Jane',
        surname: 'Doe',
        display_name: 'Jane Doe',
        borrow_check: 'checked',
        edevices_check: 'checked',
        fines_check: 'checked',
        lending_check: 'checked'
      )
    end

    describe :affiliation do
      it 'requires an affiliation' do
        patron.affiliation = nil
        expect { form.submit! }.to raise_error(Error::ForbiddenError)
      end

      it 'requires a Berkeley affiliation' do
        patron.affiliation = Patron::Affiliation::COMMUNITY_COLLEGE
        expect { form.submit! }.to raise_error(Error::ForbiddenError)
      end
    end

    describe :patron_type do
      it 'requires a patron type' do
        patron.type = nil
        expect { form.submit! }.to raise_error(Error::ForbiddenError)
      end

      allowed_patron_types.each do |t|
        it "allows #{Patron::Type.name_of(t)}" do
          patron.type = t
          expect { form.submit! }.to have_enqueued_job(StudentEdevicesLoanJob).with(patron.id)
        end
      end

      forbidden_patron_types.each do |t|
        it "disallows #{Patron::Type.name_of(t)}" do
          patron.type = t
          expect { form.submit! }.to raise_error(Error::ForbiddenError)
        end
      end
    end

    describe 'validations' do
      %i[borrow_check edevices_check fines_check lending_check].each do |field|
        it "requires an explicit opt-in for #{field}" do
          form.send("#{field}=", nil)
          expect { form.submit! }.to raise_error(ActiveModel::ValidationError)
        end
      end

      it 'requires a display name' do
        form.display_name = nil
        expect { form.submit! }.to raise_error(ActiveModel::ValidationError)
      end

      it 'requires a given name' do
        form.given_name = nil
        expect { form.submit! }.to raise_error(ActiveModel::ValidationError)
      end

      it 'requires a surname' do
        form.surname = nil
        expect { form.submit! }.to raise_error(ActiveModel::ValidationError)
      end

      it 'requries an email address' do
        patron.email = nil
        expect { form.submit! }.to raise_error(ActiveModel::ValidationError)
      end

      it 'requires a valid-ish email address' do
        patron.email = '<jane at berkeley>'
        expect { form.submit! }.to raise_error(ActiveModel::ValidationError)
      end
    end

  end
end
