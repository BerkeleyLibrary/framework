source 'https://rubygems.org'

git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '2.7.2'

gem 'awesome_print', '>=1.8.0'
gem 'bootsnap', '>= 1.1.0', require: false
gem 'bootstrap'
gem 'coffee-rails', '~> 5.0'
gem 'ipaddress'
gem 'jbuilder', '~> 2.5'
gem 'jquery-rails'
gem 'jquery-ui-rails'
gem 'lograge', '>=0.11.2'
gem 'net-ssh'
gem 'netaddr', '~> 1.5', '>= 1.5.1'
gem 'omniauth-cas',
    git: 'https://github.com/dlindahl/omniauth-cas.git',
    ref: '7087bda829e14c0f7cab2aece5045ad7015669b1'
gem 'ougai', '>=1.8.2'
gem 'pg', '~> 1.2'
gem 'prawn', '~> 2.3.0'
gem 'puma', '~> 3.11'
gem 'rails', '~> 6.0.3'
gem 'recaptcha', '~> 4.13'
gem 'turbolinks', '~> 5'
gem 'typesafe_enum', '~> 0.1.9'
gem 'tzinfo-data', platforms: %i[mingw mswin x64_mingw jruby]
gem 'uglifier', '>= 1.3.0'

group :development, :test do
  gem 'brakeman'
  gem 'bundle-audit'
  gem 'byebug', platforms: %i[mri mingw x64_mingw]
  gem 'colorize'
  gem 'dotenv', '~> 2.7'
  gem 'rspec'
  gem 'rspec-rails'
  gem 'rspec-support'
  gem 'rspec_junit_formatter'
  gem 'ruby-prof', '~> 0.17.0'
  gem 'vcr'
  gem 'webmock'
end

group :development do
  gem 'listen', '>= 3.0.5', '< 3.2'
  gem 'rubocop', '~> 0.74.0'
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'
  gem 'web-console', '>= 3.3.0'
end

group :test do
  gem 'capybara'
  gem 'concurrent-ruby', '~> 1.1'
  gem 'selenium-webdriver'
  gem 'simplecov', '~> 0.16.1', require: false
  gem 'simplecov-rcov', require: false
end
