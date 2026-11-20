require 'capybara/selenium/driver'

# Chrome can report a node that no longer belongs to the current document as
# UnknownError rather than StaleElementReferenceError. Capybara does not retry
# UnknownError, so this can make visibility checks fail intermittently during navigation.
# Translate only this specific error into StaleElementReferenceError so Capybara
# reloads the element and retries within its existing timeout.
# @see https://ucblib.atlassian.net/browse/AP-945
module ChromeNodeVisibility
  def visible?
    super
  rescue Selenium::WebDriver::Error::UnknownError => e
    raise unless e.message.include?('Node with given id does not belong to the document')

    raise Selenium::WebDriver::Error::StaleElementReferenceError, e.message
  end
end

Capybara::Selenium::ChromeNode.prepend(ChromeNodeVisibility)
