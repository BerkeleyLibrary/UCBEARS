require 'rails_helper'

describe GalcRequestForm do
  it 'limits authorization by by patron type' do
    tests = {
      Patron::Type::FACULTY => true,
      Patron::Type::GRAD_STUDENT => true,
      Patron::Type::LIBRARY_STAFF => true,
      Patron::Type::MANAGER => true,
      Patron::Type::STAFF => true,
      Patron::Type::UNDERGRAD => true,
      Patron::Type::UNDERGRAD_SLE => true,
      Patron::Type::POST_DOC => false
    }

    aggregate_failures 'patron types' do
      tests.each do |patron_type, authorized|
        patron = Patron::Record.new(affiliation: Patron::Affiliation::UC_BERKELEY, type: patron_type)
        form = GalcRequestForm.new(patron: patron)
        if authorized
          expect { form.authorize! }.not_to raise_error
        else
          expect { form.authorize! }.to raise_error(Error::ForbiddenError)
        end
      end
    end
  end

  describe :support_email do
    it 'has a default value' do
      patron = Patron::Record.new(affiliation: Patron::Affiliation::UC_BERKELEY, type: Patron::Type::LIBRARY_STAFF)
      form = GalcRequestForm.new(patron: patron)
      expect(form.support_email).to eq('eref@library.berkeley.edu')
    end
  end

  describe :patron_email do
    it 'defaults to the email from the patron record' do
      patron = Patron::Record.new(
        affiliation: Patron::Affiliation::UC_BERKELEY,
        type: Patron::Type::LIBRARY_STAFF,
        email: 'pince@library.berkeley.edu'
      )
      form = GalcRequestForm.new(patron: patron)
      expect(form.patron_email).to eq('pince@library.berkeley.edu')
    end
  end

  describe :submit! do
    it 'submits the form' do
      patron = Patron::Record.new(
        affiliation: Patron::Affiliation::UC_BERKELEY,
        type: Patron::Type::LIBRARY_STAFF,
        name: 'Irma Pince',
        email: 'pince@library.berkeley.edu',
        id: 123_456
      )
      form = GalcRequestForm.new(
        patron: patron,
        borrow_check: 'checked',
        fine_check: 'checked'
      )
      expect { form.submit! }.to have_enqueued_job(GalcRequestJob).with(patron.id)
    end
  end
end
