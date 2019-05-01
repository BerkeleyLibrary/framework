require 'test_helper'

class GalcRequestFormTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  def test_eligibility_validation_for_eligible_faculty
    patron = Patron::Record.new(
      id: 111111,
      name: "test-111111",
      type: "4",
      note: "book scan eligible"
      )
    form = GalcRequestForm.new(
      display_name: "Test1",
      patron: patron,
    )

    assert_nothing_raised do
      form.note_validate!
    end
  end

  def test_eligibility_validation_for_ineligible_faculty
    patron = Patron::Record.new(
      id: 111112,
      name: "test-111112",
      type: "4",
      )
    form = GalcRequestForm.new(
      display_name: "Test2",
      patron: patron,
    )

    assert_raises Error::FacultyNoteError do
      form.note_validate!
    end
  end

  def test_eligibility_validation_for_eligible_undergrad
    patron = Patron::Record.new(
      id: 111113,
      name: "test-111113",
      type: "1",
      note: "book scan eligible"
      )
    form = GalcRequestForm.new(
      display_name: "Test3",
      patron: patron,
    )

    assert_nothing_raised do
      form.note_validate!
    end
  end

  def test_eligibility_validation_for_ineligible_undergrad
    patron = Patron::Record.new(
      id: 111114,
      name: "test-111114",
      type: "1",
      note: "garbage"
      )
    form = GalcRequestForm.new(
      display_name: "Test4",
      patron: patron,
    )

    assert_raises Error::StudentNoteError do
      form.note_validate!
    end
  end

  def test_eligibility_validation_for_eligible_grad_student
    patron = Patron::Record.new(
      id: 111115,
      name: "test-111115",
      type: "3",
      note: "book scan eligible"
      )
    form = GalcRequestForm.new(
      display_name: "Test5",
      patron: patron,
    )

    assert_nothing_raised do
      form.note_validate!
    end
  end

  def test_eligibility_validation_for_ineligible_grad_student
    patron = Patron::Record.new(
      id: 111116,
      name: "test-111116",
      type: "3"
      )
    form = GalcRequestForm.new(
      display_name: "Test6",
      patron: patron,
    )

    assert_raises Error::StudentNoteError do
      form.note_validate!
    end
  end

  def test_eligibility_validation_for_other_patron_type
    patron = Patron::Record.new(
      id: 111117,
      name: "test-111117",
      type: "6",
      note: "book scan eligible"
      )
    form = GalcRequestForm.new(
      display_name: "Test7",
      patron: patron,
    )

    assert_nothing_raised do
      form.note_validate!
    end
  end

  def test_eligibility_validation_for_other_patron_type
    patron = Patron::Record.new(
      id: 111118,
      name: "test-111118",
      type: "12"
      )
    form = GalcRequestForm.new(
      display_name: "Test8",
      patron: patron,
    )

    assert_raises Error::GeneralNoteError do
      form.note_validate!
    end
  end
 
end

