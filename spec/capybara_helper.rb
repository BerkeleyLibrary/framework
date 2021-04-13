require 'rails_helper'
require 'support/selenium_helper'

UCBLIT::SeleniumHelper.configure!

# Capybara artifact path
# (see https://www.rubydoc.info/github/jnicklas/capybara/Capybara.configure)
#
# NOTE: Rails' system test helpers insist on writing screenshots to
#       `tmp/screenshots` regardless of Capybara configuration:
#       see https://github.com/rails/rails/issues/41828.
#
#       In the Docker image we symlink this to `artifacts/screenshots`.
Capybara.save_path = 'artifacts/capybara'
