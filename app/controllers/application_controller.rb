class ApplicationController < ActionController::Base
  include AuthHandling
  include ErrorHandling

  before_action :set_support_email

  def redirect_with_params(opts={})
    redirect_to request.parameters.update(opts)
  end

  private

  def set_support_email
    @support_email = 'privdesk@library.berkeley.edu'
  end
end
