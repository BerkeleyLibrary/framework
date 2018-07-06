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
    @employee = { email: 'dcschmidt@berkeley.edu',
                  employee_id: '011822839',
                  firstname: 'Daniel',
                  lastname: 'Schmidt' }

    # Use a mock to ensure we're sending the right SSH command
    @ssh_mock = Minitest::Mock.new
    @ssh_mock.expect :exec!, nil, [
      [
        "/home/altmedia/bin/mkcallnote",
        "#{@now.strftime('%Y%m%d')} library book scan eligible [litscript]",
        @employee[:employee_id],
      ].shelljoin
    ]
  end

  test "PatronJob triggers confirmation email on success" do
    travel_to @now do
      Net::SSH.stub :start, ssh_connection, @ssh_mock do
        UpdatePatronJob.perform_now(@employee)

        email = ActionMailer::Base.deliveries.last
        assert_equal @employee[:email], email.to[0]
        assert_equal 'alt-media scanning service opt-in', email.subject
      end
    end
  end

  test "PatronJob emails the admin on ssh exception" do
    travel_to @now do
      Net::SSH.stub :start, ssh_connection(:raised), @ssh_mock do
        assert_raises StandardError do
          UpdatePatronJob.perform_now(@employee)
        end

        email = ActionMailer::Base.deliveries.last
        assert_equal @admin_email, email.to[0]
        assert_equal 'alt-media scanning patron opt-in failure', email.subject
      end
    end
  end

  test "PatronJob emails the admin on failed script" do
    travel_to @now do
      Net::SSH.stub :start, ssh_connection(:failed), @ssh_mock do
        assert_raises StandardError do
          UpdatePatronJob.perform_now(@employee)
        end

        email = ActionMailer::Base.deliveries.last
        assert_equal @admin_email, email.to[0]
        assert_equal 'alt-media scanning patron opt-in failure', email.subject
      end
    end
  end

  private

    # Stub that checks we've passed the right parameters to Net::SSH.start and
    # returns an appropriate text response. Note that the response from the
    # mock above is actually discarded by the stub -- not sure why.
    def ssh_connection(result=nil)
      lambda do |host, user, opts|
        assert_equal 'vm161.lib.berkeley.edu', host
        assert_equal 'altmedia', user
        assert_equal ({ non_interactive: true }), opts

        case result
        when :raised then raise StandardError, "SSH connection failed"
        when :failed then 'Failed'
                     else 'Finished Successfully'
        end
      end
    end
end
