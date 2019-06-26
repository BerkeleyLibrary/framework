require 'test_helper'

class ScanRequestFormTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  ALLOWED_PATRON_TYPES = [
    Patron::Type::FACULTY,
    Patron::Type::VISITING_SCHOLAR,
  ]

  FORBIDDEN_PATRON_TYPES = [
    Patron::Type::UNDERGRAD,
    Patron::Type::UNDERGRAD_SLE,
    Patron::Type::GRAD_STUDENT,
    Patron::Type::MANAGER,
    Patron::Type::LIBRARY_STAFF,
    Patron::Type::STAFF,
    Patron::Type::POST_DOC,
  ]

  ALLOWED_PATRON_TYPES.each do |patron_type|
    test "patron_type_#{patron_type}_allowed" do
      form = ScanRequestForm.new(
        opt_in: "true",
        patron: Patron::Record.new(
          affiliation: Patron::Affiliation::UC_BERKELEY,
          email: 'winner@civil-war.com',
          id: '1865',
          type: patron_type,
        ),
        patron_name: "Ulysses S. Grant",
      )

      assert form.valid?
      assert_equal '1865', form.patron_id
      assert_equal 'winner@civil-war.com', form.patron_email

      begin
        form.patron.blocks = "something"
        assert_raises(Error::ForbiddenError) { form.submit! }
      ensure
        form.patron.blocks = nil
      end

      begin
        form.patron.affiliation = Patron::Affiliation::COMMUNITY_COLLEGE
        assert_raises(Error::ForbiddenError) { form.submit! }
      ensure
        form.patron.affiliation = Patron::Affiliation::UC_BERKELEY
      end

      begin
        form.opt_in = "maybe"
        refute form.valid?
      ensure
        form.opt_in = "true"
      end

      job_args = [{
        # NOTE(dcschmidt): The order actually matters here.
        # See: https://github.com/rails/rails/issues/33847
        patron: {
          email: 'winner@civil-war.com',
          id: '1865',
          name: "Ulysses S. Grant",
        },
      }]

      assert_enqueued_with(job: ScanRequestOptInJob, args: job_args) do
        form.opt_in = "true"
        form.submit!
      end

      assert_enqueued_with(job: ScanRequestOptOutJob, args: job_args) do
        form.opt_in = "false"
        form.submit!
      end
    end
  end

  FORBIDDEN_PATRON_TYPES.each do |type|
    test "patron_type_#{type}_forbidden" do
      assert_raises(Error::ForbiddenError) do
        ScanRequestForm.new(
          patron: Patron::Record.new(
            affiliation: Patron::Affiliation::UC_BERKELEY,
            email: 'winner@civil-war.com',
            id: '1865',
            type: type,
          ),
          patron_name: "Placeholder Name",
          opt_in: "true",
        ).valid?
      end
    end
  end
end
