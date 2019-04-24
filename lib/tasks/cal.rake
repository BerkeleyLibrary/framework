require 'ci/reporter/rake/minitest'

ENV['GENERATE_REPORTS'] ||= 'true'

namespace :cal do
  namespace :test do
    desc "Run the test suite in Jenkins CI"
    task :ci => %w(environment ci:setup:minitest test brakeman)
  end
end
