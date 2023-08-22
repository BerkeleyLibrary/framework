# Base class for all controllers
class ApplicationController < ActionController::Base
  include AuthSupport
  include ExceptionHandling

  # @!group Class Attributes
  # @!attribute [rw]
  # Value of the "Questions?" mailto link in the footer
  # @return [String]
  class_attribute :support_email, default: 'helpbox-library@berkeley.edu'
  helper_method :support_email
  # @!endgroup

  # Return 404 if the requested path is in ENV["LIT_HIDDEN_PATHS"]
  before_action :hide_paths

  # @see https://api.rubyonrails.org/classes/ActionController/RequestForgeryProtection/ClassMethods.html
  protect_from_forgery with: :exception

  private

  helper_method :authenticated?

  # @return Regexp Pattern determining whether a request should be "hidden"
  #
  # For example, "LIT_HIDDEN_PATHS='foo bar.*'" will result in a regexp that
  # matches either "foo" OR "bar.*".
  def hidden_paths_re
    @_hidden_paths_re ||= Regexp.union(
      (ENV['LIT_HIDDEN_PATHS'] || '')
        .split.map(&:strip).reject(&:empty?).map { |s| Regexp.new(s) }
    )
  end

  # Before filter that 404s requests whose paths match hidden_paths_re
  def hide_paths
    hidden_paths_re.match(request.path) do
      render file: Rails.root.join('public/404.html'), status: :not_found
    end
  end

  # Perform a redirect but keep all existing request parameters
  #
  # This is a workaround for not being able to redirect a POST/PUT request.
  def redirect_with_params(opts = {})
    redirect_to request.parameters.update(opts)
  end
end
