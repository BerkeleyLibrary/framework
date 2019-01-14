source 'https://rubygems.org'

git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '2.5.1'

gem 'bootsnap', '>= 1.1.0', require: false
gem 'bootstrap'
gem 'coffee-rails', '~> 4.2'
gem 'jbuilder', '~> 2.5'
gem 'jquery-rails'
gem 'net-ssh'
gem 'omniauth-cas'
gem 'puma', '~> 3.11'
gem 'rails', '~> 5.2.0'
gem 'recaptcha'
gem 'sass-rails', '~> 5.0'
gem 'sqlite3'
gem 'turbolinks', '~> 5'
gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]
gem 'uglifier', '>= 1.3.0'

group :development, :test do
  gem 'brakeman'
  gem "bundle-audit"
  gem 'byebug', platforms: [:mri, :mingw, :x64_mingw]
  gem 'webmock'
  gem 'vcr'
  gem 'yard'
  gem 'yard-minitest'
end

group :development do
  gem 'listen', '>= 3.0.5', '< 3.2'
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'
  gem 'web-console', '>= 3.3.0'
end

group :test do
  gem 'capybara', '>= 2.15', '< 4.0'
  gem 'chromedriver-helper'
  gem 'ci_reporter_minitest'
  gem 'selenium-webdriver'
  gem "simplecov", "~> 0.16.1", require: false
  gem 'simplecov-rcov', require: false
end
