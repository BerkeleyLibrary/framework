# Checks on the health of critical application dependencies
#
# @see https://tools.ietf.org/id/draft-inadarei-api-health-check-01.html JSON Format
# @see https://www.consul.io/docs/agent/checks.html StatusCode based on Consul
#
# @todo We could improve on this by adding a few additional checks, namely:
#   - That we can actually send emails
#   - That we can add notes to patrons (SSH access to the millennium scripts)
class HealthCheck
  STATUS_FAIL = 'fail'
  STATUS_PASS = 'pass'
  STATUS_WARN = 'warn'
  TEST_PATRON_ID = '012158720'

  def initialize
    @status = STATUS_PASS
    @details = {
      "patron_api:find" => {
        "status" => STATUS_PASS,
      },
    }

    begin
      Patron::Record.find(TEST_PATRON_ID)
    rescue => e
      @status = STATUS_WARN
      @details["patron_api:find"]["status"] = STATUS_WARN
      @details["patron_api:find"]["output"] = e.class.name
    end
  end

  def as_json(*)
    {
      "status" => @status,
      "details" => @details,
    }
  end

  def http_status_code
    if passing?
      200
    elsif warning?
      429
    else
      500
    end
  end

  def passing?
    STATUS_PASS == @status
  end

  def warning?
    STATUS_WARN == @status
  end

  def failing?
    STATUS_FAIL == @status
  end
end
