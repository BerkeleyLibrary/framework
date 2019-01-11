require 'ci/reporter/rake/minitest'

ENV['GENERATE_REPORTS'] ||= 'true'

namespace :test do
  desc "Run tests with JUnit XML output"
  task :junit => %w(ci:setup:minitest test)
end
