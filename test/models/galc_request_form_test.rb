require 'test_helper'

class GalcRequestFormTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  def test_eligibility_validation_for_eligible_faculty
    patron = Patron::Record.new(
      id: 111111,
      name: "test-111111",
      type: "4",
      affiliation: Patron::Affiliation::UC_BERKELEY
      )
    form = GalcRequestForm.new(
      patron: patron,
    )

    assert_nothing_raised do
      form.authorize!
    end
  end

  def test_eligibility_validation_for_eligible_undergrad
    patron = Patron::Record.new(
      id: 111113,
      name: "test-111113",
      type: "1",
      affiliation: Patron::Affiliation::UC_BERKELEY
      )
    form = GalcRequestForm.new(
      patron: patron,
    )

    assert_nothing_raised do
      form.authorize!
    end
  end

  def test_eligibility_validation_for_eligible_grad_student
    patron = Patron::Record.new(
      id: 111115,
      name: "test-111115",
      type: "3",
      affiliation: Patron::Affiliation::UC_BERKELEY
      )
    form = GalcRequestForm.new(
      patron: patron,
    )

    assert_nothing_raised do
      form.authorize!
    end
  end

  def test_eligibility_validation_for_eligible_undergrad_SLE
    patron = Patron::Record.new(
      id: 111113,
      name: "test-111117",
      type: "2",
      affiliation: Patron::Affiliation::UC_BERKELEY
      )
    form = GalcRequestForm.new(
      patron: patron,
    )

    assert_nothing_raised do
      form.authorize!
    end
  end

  def test_eligibility_validation_for_eligible_manager
    patron = Patron::Record.new(
      id: 111113,
      name: "test-111119",
      type: "5",
      affiliation: Patron::Affiliation::UC_BERKELEY
      )
    form = GalcRequestForm.new(
      patron: patron,
    )

    assert_nothing_raised do
      form.authorize!
    end
  end

  def test_eligibility_validation_for_eligible_library_staff
    patron = Patron::Record.new(
      id: 111113,
      name: "test-1111111",
      type: "6",
      affiliation: Patron::Affiliation::UC_BERKELEY
      )
    form = GalcRequestForm.new(
      patron: patron,
    )

    assert_nothing_raised do
      form.authorize!
    end
  end

  def test_eligibility_validation_for_eligible_staff
    patron = Patron::Record.new(
      id: 111113,
      name: "test-1111113",
      type: "7",
      affiliation: Patron::Affiliation::UC_BERKELEY
      )
    form = GalcRequestForm.new(
      patron: patron,
    )

    assert_nothing_raised do
      form.authorize!
    end
  end

  def test_eligibility_validation_for_ineligible_postdoc
    patron = Patron::Record.new(
      id: 111114,
      name: "test-1111114",
      type: "12",
      affiliation: Patron::Affiliation::UC_BERKELEY
      )
    form = GalcRequestForm.new(
      patron: patron,
    )

    assert_raises Error::ForbiddenError do
      form.authorize!
    end
  end
 
end