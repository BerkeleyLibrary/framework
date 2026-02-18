source 'https://rubygems.org'

git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby File.read('.ruby-version').strip

gem 'base64'
gem 'berkeley_library-docker', '~> 0.2.0'
gem 'berkeley_library-location', '~> 4.2.0'
gem 'berkeley_library-logging', '~> 0.2', '>= 0.2.7'
gem 'berkeley_library-marc', '~> 0.3.1'
gem 'berkeley_library-tind', '~> 0.8.0'
gem 'berkeley_library-util', '~> 0.3'
gem 'bootstrap'
gem 'dotenv-rails', '~> 2.8.1', require: 'dotenv/rails-now'
gem 'faraday'
gem 'good_job', '~> 3.99'
gem 'ipaddress'
gem 'jaro_winkler', '~> 1.5.5'
gem 'jquery-rails'
gem 'jquery-ui-rails'
gem 'jwt', '~> 1.5', '>= 1.5.4'
gem 'lograge', '>=0.11.2'
gem 'netaddr', '~> 1.5', '>= 1.5.1'
gem 'net-ssh'
gem 'okcomputer', '~> 1.19'
gem 'omniauth', '~> 1.9', '>= 1.9.2'
gem 'omniauth-cas', '~> 2.0'
gem 'pg', '~> 1.2'
gem 'prawn', '~> 2.4'
gem 'puma', '~> 4.3', '>= 4.3.12'
gem 'rails', '~> 7.1.6'
gem 'recaptcha', '~> 4.13'
gem 'sprockets', '~> 4.0'
gem 'tzinfo-data', platforms: %i[windows jruby]

group :development, :test do
  gem 'brakeman'
  gem 'bundle-audit'
  gem 'byebug', platforms: %i[mri windows]
  gem 'colorize'
  gem 'database_cleaner-active_record', '~> 2.1'
  gem 'roo', '~> 2.8'
  gem 'rspec', '~> 3.13'
  gem 'rspec_junit_formatter', '~> 0.5'
  gem 'rspec-rails', '~> 6.1'
  gem 'ruby-prof', '~> 1.3.0'
  gem 'webmock'
end

group :development do
  gem 'listen', '~> 3.2'
  gem 'rubocop', '~> 1.77.0'
  gem 'rubocop-rails', '~> 2.32.0', require: false
  gem 'rubocop-rspec', '~> 3.6.0', require: false
  gem 'rubocop-rspec_rails', require: false
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'
  gem 'web-console', '>= 3.3.0'
end

group :test do
  gem 'capybara', '~> 3.36'
  gem 'concurrent-ruby', '~> 1.1'
  gem 'selenium-webdriver', '~> 4.0'
  gem 'simplecov', '~> 0.22', require: false
  gem 'simplecov-rcov', '~> 0.3.7', require: false
end
