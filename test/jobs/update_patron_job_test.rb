require 'shellwords'
require 'test_helper'

class UpdatePatronJobTest < ActiveJob::TestCase
  setup do
    # Notes depend on the time, so we fix this in tests using travel_to():
    #   http://api.rubyonrails.org/v5.2/classes/ActiveSupport/Testing/TimeHelpers.html#method-i-travel_to
    @now = Date.new(2018, 1, 1)

    # TODO: This should probably be configurable.
    @admin_email = 'dzuckerm@library.berkeley.edu'

    # Dummy employee data.
    @employee = { email: 'dzuckerm@library.berkeley.edu',
                  employee_id: '011822839',
                  displayname: 'David Zuckerman' }
  end

  test "PatronJob triggers confirmation email on success" do
    with_stubbed_ssh(:succeeded) do
      UpdatePatronJob.perform_now(@employee)

      email = ActionMailer::Base.deliveries.last
      assert_equal @employee[:email], email.to[0]
      assert_equal 'alt-media scanning service opt-in', email.subject
    end
  end

  test "PatronJob emails the admin on ssh exception" do
    with_stubbed_ssh(:raised) do
      assert_raises StandardError do
        UpdatePatronJob.perform_now(@employee)
      end

      email = ActionMailer::Base.deliveries.last
      assert_equal @admin_email, email.to[0]
      assert_equal 'alt-media scanning patron opt-in failure', email.subject
    end
  end

  test "PatronJob emails the admin on failed script" do
    with_stubbed_ssh(:failed) do
      assert_raises StandardError do
        UpdatePatronJob.perform_now(@employee)
      end

      email = ActionMailer::Base.deliveries.last
      assert_equal @admin_email, email.to[0]
      assert_equal 'alt-media scanning patron opt-in failure', email.subject
    end
  end

  private

    # Executes the block in a context in which Net::SSH.start() is stubbed out
    # to return a defined "result" and assert that we've passed the right args.
    def with_stubbed_ssh(result, &block)
      stubbed_connection = lambda do |host, user, opts|
        assert_equal 'vm161.lib.berkeley.edu', host
        assert_equal 'altmedia', user
        assert_equal ({ non_interactive: true }), opts

        case result
        when :raised then raise StandardError, "SSH connection failed"
        when :failed then 'Failed'
                     else 'Finished Successfully'
        end
      end

      travel_to @now do
        Net::SSH.stub :start, stubbed_connection, &block
      end
    end
end
