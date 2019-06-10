require 'test_helper'

class DoemoffStudyRoomUseFormTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  def test_eligibility_validation_for_eligible_faculty
    patron = Patron::Record.new(
      id: 111111,
      name: "test-111111",
      type: "4",
      affiliation: '0',
      email: "whoever@example.com",
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
      email: "whoever@example.com",
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
 
end

