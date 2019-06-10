module PatronEligibilityTests
  extend ActiveSupport::Concern

  included do
    def assert_forbidden(&block)
      assert_raises(Error::ForbiddenError, &block)
    end
  end

  class_methods do
    # Adds test cases for the given form_model's authorize! method based on the
    # provided specs. The specs are a list of lists, where the first element
    # of each sublist is either true/false indicating whether authorization
    # should succeed or fail, and the second element is a hash of init args
    # for the form model under test.
    def add_eligibility_tests(form_model, specs)
      specs.each do |assertion, form_data|
        test "#{assertion} for #{form_data}" do
          send(assertion) do
            form = form_model.new(**form_data)
            form.authorize!
          end
        end
      end
    end
  end
end
