require 'rails_helper'
require 'capybara/rspec'
require 'support/selenium_helper'

UCBLIT::SeleniumHelper.configure!

Capybara.save_path = 'artifacts/screenshots'
