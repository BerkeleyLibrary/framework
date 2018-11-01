class ApplicationController < ActionController::Base
  include AuthHandling
  include ErrorHandling

  # @!group Class Attributes
  # @!attribute [rw]
  # Value of the "Questions?" mailto link in the footer
  # @return [String]
  class_attribute :support_email, default: 'privdesk@library.berkeley.edu'
  # @!endgroup

  helper_method :support_email

  def redirect_with_params(opts={})
    redirect_to request.parameters.update(opts)
  end
end
