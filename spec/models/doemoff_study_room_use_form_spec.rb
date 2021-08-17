require 'rails_helper'

describe DoemoffStudyRoomUseForm do
  # include ActiveJob::TestHelper

  describe :validate! do
    it 'validates a eligible faculty' do
      patron = Patron::Record.new(
        id: 111_111,
        name: 'test-111111',
        type: '4',
        affiliation: '0',
        email: 'whoever@example.com'
      )
      form = DoemoffStudyRoomUseForm.new(
        display_name: 'Test1',
        patron: patron,
        borrow_check: 'checked',
        fines_check: 'checked',
        roomUse_check: 'checked'
      )

      expect(form.validate!).to eq(true)
    end

    it 'validates a eligible undergrad' do
      patron = Patron::Record.new(
        id: 111_113,
        name: 'test-111113',
        type: '1',
        affiliation: '0',
        email: 'whoever@example.com'
      )
      form = DoemoffStudyRoomUseForm.new(
        display_name: 'Test3',
        patron: patron,
        borrow_check: 'checked',
        fines_check: 'checked',
        roomUse_check: 'checked'
      )

      expect(form.validate!).to eq(true)
    end
  end

  describe :authorize! do
    # For the case of a user who logs in with a CalNet account but has no Millennium patron account
    it 'fails for users without patron accounts' do
      patron = nil
      form = DoemoffStudyRoomUseForm.new(
        display_name: 'Test3',
        patron: patron,
        borrow_check: 'checked',
        fines_check: 'checked',
        roomUse_check: 'checked'
      )

      expect { form.authorize! }.to raise_error(Error::PatronNotFoundError)
    end
  end

  describe :submit! do
    it 'submits a job' do
      patron = Patron::Record.new(
        id: 111_111,
        name: 'test-111111',
        type: '4',
        affiliation: '0',
        email: 'whoever@example.com'
      )
      form = DoemoffStudyRoomUseForm.new(
        display_name: 'Test1',
        patron: patron,
        borrow_check: 'checked',
        fines_check: 'checked',
        roomUse_check: 'checked'
      )
      expect { form.submit! }.to have_enqueued_job(DoemoffStudyRoomUseJob).with(patron.id)
    end
  end
end
