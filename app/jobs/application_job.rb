class ApplicationJob < ActiveJob::Base
  def today
    @today ||= Time.now.strftime('%Y%m%d')
  end
end
