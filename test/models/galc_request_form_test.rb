require 'test_helper'

class GalcRequestFormTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper
  include PatronEligibilityTests

  add_eligibility_tests(GalcRequestForm, [
    [
      :assert_nothing_raised,
      {
        patron: Patron::Record.new(
          affiliation: Patron::Affiliation::UC_BERKELEY,
          type: Patron::Type::FACULTY,
        ),
      },
    ],
    [
      :assert_nothing_raised,
      {
        patron: Patron::Record.new(
          affiliation: Patron::Affiliation::UC_BERKELEY,
          type: Patron::Type::GRAD_STUDENT,
        ),
      },
    ],
    [
      :assert_nothing_raised,
      {
        patron: Patron::Record.new(
          affiliation: Patron::Affiliation::UC_BERKELEY,
          type: Patron::Type::LIBRARY_STAFF,
        ),
      },
    ],
    [
      :assert_nothing_raised,
      {
        patron: Patron::Record.new(
          affiliation: Patron::Affiliation::UC_BERKELEY,
          type: Patron::Type::MANAGER,
        ),
      },
    ],
    [
      :assert_nothing_raised,
      {
        patron: Patron::Record.new(
          affiliation: Patron::Affiliation::UC_BERKELEY,
          type: Patron::Type::STAFF,
        ),
      },
    ],
    [
      :assert_nothing_raised,
      {
        patron: Patron::Record.new(
          affiliation: Patron::Affiliation::UC_BERKELEY,
          type: Patron::Type::UNDERGRAD,
        ),
      },
    ],
    [
      :assert_nothing_raised,
      {
        patron: Patron::Record.new(
          affiliation: Patron::Affiliation::UC_BERKELEY,
          type: Patron::Type::UNDERGRAD_SLE,
        ),
      },
    ],
    [
      :assert_forbidden,
      {
        patron: Patron::Record.new(
          affiliation: Patron::Affiliation::UC_BERKELEY,
          type: Patron::Type::POST_DOC,
        ),
      },
    ],
  ])
end
