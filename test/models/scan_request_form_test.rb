require 'test_helper'

class ScanRequestFormTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  def test_submit_validates_before_submission
    form = ScanRequestForm.new(patron_blocks: '!')

    assert_raises(ActiveModel::ValidationError) { form.submit! }
    assert_includes form.errors, :opt_in
    assert_includes form.errors, :patron_blocks
    assert_includes form.errors, :patron_email
    assert_includes form.errors, :patron_name
    assert_includes form.errors, :patron_type
  end

  def test_allows_submissions_by_faculty_and_visiting_scholars
    %w(4 22).each do |type|
      form = ScanRequestForm.new(patron_type: type)
      refute form.valid?
      assert_empty form.errors[:patron_type]
    end
  end

  def test_disallows_other_patron_types
    form = ScanRequestForm.new(patron_type: '21')
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
          email: 'winner@civil-war',
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
          email: 'winner@civil-war',
          id: '1865',
          name: "Ulysses S. Grant",
        },
      }],
    ) { opt_out! }
  end

private

  def opt_in!
    form = ScanRequestForm.new(
      opt_in: "yes",
      patron_name: "Ulysses S. Grant",
      patron_email: 'winner@civil-war',
      patron_employee_id: '1865',
      patron_type: Patron::Type::VISITING_SCHOLAR,
      patron_affiliation: Patron::Affiliation::UC_BERKELEY,
    )

    assert form.opted_in?, '... opting in'

    form.submit!
  end

  def opt_out!
    form = ScanRequestForm.new(
      opt_in: "no",
      patron_name: "Ulysses S. Grant",
      patron_email: 'winner@civil-war',
      patron_employee_id: '1865',
      patron_type: Patron::Type::VISITING_SCHOLAR,
      patron_affiliation: Patron::Affiliation::UC_BERKELEY,
    )

    refute form.opted_in?, '... opting out'

    form.submit!
  end
end
