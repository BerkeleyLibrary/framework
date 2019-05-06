require 'test_helper'

class GalcRequestFormTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  def test_eligibility_validation_for_eligible_faculty
    patron = Patron::Record.new(
      id: 111111,
      name: "test-111111",
      type: "4",
      note: "20180931 GALC eligible [litscript]"
      )
    form = GalcRequestForm.new(
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
      patron: patron,
    )

    assert_raises Error::GalcNoteError do
      form.note_validate!
    end
  end

  def test_eligibility_validation_for_eligible_undergrad
    patron = Patron::Record.new(
      id: 111113,
      name: "test-111113",
      type: "1",
      note: "20180931 GALC eligible [litscript]"
      )
    form = GalcRequestForm.new(
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
      patron: patron,
    )

    assert_raises Error::GalcNoteError do
      form.note_validate!
    end
  end

  def test_eligibility_validation_for_eligible_grad_student
    patron = Patron::Record.new(
      id: 111115,
      name: "test-111115",
      type: "3",
      note: "20180931 GALC eligible [litscript]"
      )
    form = GalcRequestForm.new(
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
      patron: patron,
    )

    assert_raises Error::GalcNoteError do
      form.note_validate!
    end
  end

  def test_eligibility_validation_for_eligible_undergrad_SLE
    patron = Patron::Record.new(
      id: 111113,
      name: "test-111117",
      type: "2",
      note: "20180931 GALC eligible [litscript]"
      )
    form = GalcRequestForm.new(
      patron: patron,
    )

    assert_nothing_raised do
      form.note_validate!
    end
  end

  def test_eligibility_validation_for_ineligible_undergrad_SLE
    patron = Patron::Record.new(
      id: 111114,
      name: "test-111118",
      type: "2",
      note: "garbage"
      )
    form = GalcRequestForm.new(
      patron: patron,
    )

    assert_raises Error::GalcNoteError do
      form.note_validate!
    end
  end

  def test_eligibility_validation_for_eligible_manager
    patron = Patron::Record.new(
      id: 111113,
      name: "test-111119",
      type: "5",
      note: "20180931 GALC eligible [litscript]"
      )
    form = GalcRequestForm.new(
      patron: patron,
    )

    assert_nothing_raised do
      form.note_validate!
    end
  end

  def test_eligibility_validation_for_ineligible_manager
    patron = Patron::Record.new(
      id: 111114,
      name: "test-1111110",
      type: "5",
      note: "garbage"
      )
    form = GalcRequestForm.new(
      patron: patron,
    )

    assert_raises Error::GalcNoteError do
      form.note_validate!
    end
  end

  def test_eligibility_validation_for_eligible_library_staff
    patron = Patron::Record.new(
      id: 111113,
      name: "test-1111111",
      type: "6",
      note: "20180931 GALC eligible [litscript]"
      )
    form = GalcRequestForm.new(
      patron: patron,
    )

    assert_nothing_raised do
      form.note_validate!
    end
  end

  def test_eligibility_validation_for_ineligible_library_staff
    patron = Patron::Record.new(
      id: 111114,
      name: "test-1111112",
      type: "6",
      note: "garbage"
      )
    form = GalcRequestForm.new(
      patron: patron,
    )

    assert_raises Error::GalcNoteError do
      form.note_validate!
    end
  end

  def test_eligibility_validation_for_eligible_staff
    patron = Patron::Record.new(
      id: 111113,
      name: "test-1111113",
      type: "7",
      note: "20180931 GALC eligible [litscript]"
      )
    form = GalcRequestForm.new(
      patron: patron,
    )

    assert_nothing_raised do
      form.note_validate!
    end
  end

  def test_eligibility_validation_for_ineligible_staff
    patron = Patron::Record.new(
      id: 111114,
      name: "test-1111114",
      type: "7",
      note: "garbage"
      )
    form = GalcRequestForm.new(
      patron: patron,
    )

    assert_raises Error::GalcNoteError do
      form.note_validate!
    end
  end
 
end