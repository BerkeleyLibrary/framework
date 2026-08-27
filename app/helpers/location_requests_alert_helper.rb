module LocationRequestsAlertHelper
  def location_requests_alert
    Rails.configuration.location_requests_alert.presence
  end

  def display_location_requests_alert
    alert = location_requests_alert
    content_tag(:div, alert, class: 'alert alert-warning', role: 'alert') if alert
  end
end
