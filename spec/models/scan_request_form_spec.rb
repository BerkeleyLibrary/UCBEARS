require 'rails_helper'

describe ScanRequestForm do

  attr_reader :patron
  attr_reader :form

  describe 'allowed' do
    allowed_patron_types = [
      Patron::Type::FACULTY,
      Patron::Type::STAFF,
      Patron::Type::LIBRARY_STAFF,
      Patron::Type::MANAGER,
      Patron::Type::VISITING_SCHOLAR
    ]

    allowed_patron_types.each do |type|
      describe Patron::Type.name_of(type) do
        before(:each) do
          @patron = Patron::Record.new(
            affiliation: Patron::Affiliation::UC_BERKELEY,
            email: 'winner@civil-war.com',
            id: '1865',
            name: 'Ulysses S. Grant',
            type: type
          )

          @form = ScanRequestForm.new(
            opt_in: 'true',
            patron: patron,
            patron_name: 'Ulysses S. Grant'
          )
        end

        it 'is valid' do
          expect(form.valid?).to eq(true)
          expect(form.patron_id).to eq('1865')
          expect(ScanRequestForm.patron_eligible?(form.patron)).to eq(true)
        end

        it 'populates the patron email' do
          expect(form.patron_email).to eq('winner@civil-war.com')
        end

        it 'disallows blocked patrons' do
          form.patron.blocks = 'something'
          expect { form.submit! }.to raise_error(Error::ForbiddenError)
        end

        it 'checks patron affiliation' do
          form.patron.affiliation = Patron::Affiliation::COMMUNITY_COLLEGE
          expect { form.submit! }.to raise_error(Error::ForbiddenError)
        end

        it 'checks opt-in flag' do
          form.opt_in = 'maybe'
          expect(form.valid?).to eq(false)
        end

        it 'queues an opt-in job' do
          form.opt_in = 'true'
          expect { form.submit! }.to have_enqueued_job(ScanRequestOptInJob).with(patron.id)
        end

        it 'queues an opt-out job' do
          form.opt_in = 'false'
          expect { form.submit! }.to have_enqueued_job(ScanRequestOptOutJob).with(patron.id)
        end
      end
    end
  end

  describe 'forbidden' do
    forbidden_patron_types = [
      Patron::Type::UNDERGRAD,
      Patron::Type::UNDERGRAD_SLE,
      Patron::Type::GRAD_STUDENT,
      Patron::Type::POST_DOC
    ]

    forbidden_patron_types.each do |type|
      describe Patron::Type.name_of(type) do
        before(:each) do
          @patron = Patron::Record.new(
            affiliation: Patron::Affiliation::UC_BERKELEY,
            email: 'winner@civil-war.com',
            id: '1865',
            type: type
          )
          @form = ScanRequestForm.new(
            opt_in: 'true',
            patron: patron,
            patron_name: 'Ulysses S. Grant'
          )
        end

        it 'is invalid' do
          expect { form.valid? }.to raise_error(Error::ForbiddenError)
          expect(ScanRequestForm.patron_eligible?(form.patron)).to eq(false)
        end
      end
    end
  end

  describe :model_name do
    it 'has a human name' do
      expect(ScanRequestForm.model_name.human).to eq('Faculty Alt-Media Scanning')
    end
  end
end
