class ApplicationJob < ActiveJob::Base

  rescue_from(StandardError) do |e|
    handle_error(e)
  end

  private

  def handle_error(e)
    # generic handler that can be overridden in inherited classes
  end

end
