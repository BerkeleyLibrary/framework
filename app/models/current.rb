# see AP-513. We're bringing in Current here in order to attach the original request_id to a queued job
class Current < ActiveSupport::CurrentAttributes
  attribute :request_id

end
