require 'test_helper'

class ScanRequestFormTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  setup do
    @us_grant = Patron::Record.new(
      affiliation: Patron::Affiliation::UC_BERKELEY,
      email: 'winner@civil-war.com',
      id: '1865',
      type: Patron::Type::VISITING_SCHOLAR,
    )
  end

  def test_basics
    form = ScanRequestForm.new(patron: @us_grant)

    assert_equal '1865', form.patron_id
    assert_equal 'winner@civil-war.com', form.patron_email
    assert_equal Patron::Affiliation::UC_BERKELEY, form.patron_affiliation
    assert_equal Patron::Type::VISITING_SCHOLAR, form.patron_type
  end

  def test_submit_validates_before_submission
    form = ScanRequestForm.new(patron: Patron::Record.new(blocks: 'some'))

    assert_raises(ActiveModel::ValidationError) { form.submit! }
    assert_includes form.errors, :patron_blocks
    assert_includes form.errors, :patron_email
    assert_includes form.errors, :patron_name
    assert_includes form.errors, :patron_type
  end

  def test_allows_submissions_by_faculty_and_visiting_scholars
    %w(4 22).each do |type|
      patron = Patron::Record.new(type: type)

      form = ScanRequestForm.new(patron: patron)
      refute form.valid?
      assert_empty form.errors[:patron_type]
    end
  end

  def test_disallows_other_patron_types
    patron = Patron::Record.new(type: '21')

    form = ScanRequestForm.new(patron: patron)
    refute form.valid?
    assert_includes form.errors, :patron_type
  end

  def test_queues_ScanRequestOptInJob_on_opt_in
    assert_enqueued_with(
      job: ScanRequestOptInJob,
      args: [{
        # NOTE(dcschmidt): The order actually matters here.
        # See: https://github.com/rails/rails/issues/33847
        patron: {
          email: 'winner@civil-war.com',
          id: '1865',
          name: "Ulysses S. Grant",
        },
      }],
    ) { opt_in! }
  end

  def test_queues_ScanRequestOptOutJob_on_opt_out
    assert_enqueued_with(
      job: ScanRequestOptOutJob,
      args: [{
        # NOTE(dcschmidt): The order actually matters here.
        # See: https://github.com/rails/rails/issues/33847
        patron: {
          email: 'winner@civil-war.com',
          id: '1865',
          name: "Ulysses S. Grant",
        },
      }],
    ) { opt_out! }
  end

  private

  def opt_in!
    form = ScanRequestForm.new(
      opt_in: 'true',
      patron_name: "Ulysses S. Grant",
      patron: @us_grant,
    )

    assert form.opted_in?, '... opting in'

    form.submit!
  end

  def opt_out!
    form = ScanRequestForm.new(
      opt_in: 'false',
      patron_name: "Ulysses S. Grant",
      patron: @us_grant,
    )

    refute form.opted_in?, '... opting out'

    form.submit!
  end
end
