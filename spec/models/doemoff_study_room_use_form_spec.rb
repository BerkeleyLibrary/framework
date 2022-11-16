require 'rails_helper'

describe DoemoffStudyRoomUseForm do
  # include ActiveJob::TestHelper

  describe :validate! do
    it 'validates a eligible faculty' do
      patron = Alma::User.new
      patron.id = 111_111
      patron.name = 'test-111111'
      patron.type = 'FACULTY'
      patron.email = 'whoever@example.com'

      form = DoemoffStudyRoomUseForm.new(
        display_name: 'Test1',
        patron:,
        borrow_check: 'checked',
        fines_check: 'checked',
        room_use_check: 'checked'
      )

      expect(form.validate!).to eq(true)
    end

    it 'validates a eligible undergrad' do
      patron = Alma::User.new
      patron.id = 111_113
      patron.name = 'test-111113'
      patron.type = 'UNDERGRAD'
      patron.email = 'whoever@example.com'

      form = DoemoffStudyRoomUseForm.new(
        display_name: 'Test3',
        patron:,
        borrow_check: 'checked',
        fines_check: 'checked',
        room_use_check: 'checked'
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
        patron:,
        borrow_check: 'checked',
        fines_check: 'checked',
        room_use_check: 'checked'
      )

      expect { form.authorize! }.to raise_error(Error::PatronNotFoundError)
    end
  end

  describe :submit! do
    it 'submits a job' do
      patron = Alma::User.new
      patron.id = 111_111
      patron.name = 'test-111111'
      patron.type = 'FACULTY'
      patron.email = 'whoever@example.com'

      form = DoemoffStudyRoomUseForm.new(
        display_name: 'Test1',
        patron:,
        borrow_check: 'checked',
        fines_check: 'checked',
        room_use_check: 'checked'
      )
      expect { form.submit! }.to have_enqueued_job(DoemoffStudyRoomUseJob).with(patron.id)
    end
  end
end
