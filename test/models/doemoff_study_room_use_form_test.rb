require 'test_helper'

class DoemoffStudyRoomUseFormTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  def test_eligibility_validation_for_eligible_faculty
    patron = Patron::Record.new(
      id: 111111,
      name: "test-111111",
      type: "4",
      affiliation: '0',
      email: "whoever@example.com"
     # note: "Doe/Moffitt study room eligible"
      )
    form = DoemoffStudyRoomUseForm.new(
      display_name: "Test1",
      patron: patron,
      borrow_check: "checked",
      fines_check: "checked",
      roomUse_check: "checked"
    )

    assert_nothing_raised do
      form.validate!
    end
  end


  def test_eligibility_validation_for_eligible_undergrad
    patron = Patron::Record.new(
      id: 111113,
      name: "test-111113",
      type: "1",
      affiliation: '0',
      email: "whoever@example.com"
      #note: "Doe/Moffitt study room eligible"
      )
    form = DoemoffStudyRoomUseForm.new(
      display_name: "Test3",
      patron: patron,
      borrow_check: "checked",
      fines_check: "checked",
      roomUse_check: "checked"
    )

    assert_nothing_raised do
      form.validate!
    end
  end

  # def test_eligibility_validation_for_eligible_grad
  #   patron = Patron::Record.new(
  #     id: 111113,
  #     name: "test-111116",
  #     type: "3",
  #     #note: "Doe/Moffitt study room eligible"
  #     )
  #   form = DoemoffStudyRoomUseForm.new(
  #     display_name: "Test3",
  #     patron: patron,
  #   )

  #   assert_nothing_raised do
  #     form.note_validate!
  #   end
  # end


  # def test_eligibility_validation_for_other_patron_type
  #   patron = Patron::Record.new(
  #     id: 111117,
  #     name: "test-111117",
  #     type: "6",
  #     )
  #   form = DoemoffStudyRoomUseForm.new(
  #     display_name: "Test7",
  #     patron: patron,
  #   )

  #   assert_nothing_raised do
  #     form.note_validate!
  #   end
  # end
 
end

