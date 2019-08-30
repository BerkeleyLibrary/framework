require 'ci/reporter/rake/rspec'

# Tell CI::Reporter to generate reports
ENV['GENERATE_REPORTS'] ||= 'true'

# Tell CI:Reporter to put RSpec reports in the same place we put Brakeman and RCov
ENV['CI_REPORTS'] = 'test/reports'

namespace :cal do

  namespace :test do
    desc 'Run all specs in spec directory, with coverage'
    task :coverage do
      ENV['COVERAGE'] ||= 'true'
      Rake::Task[:spec].invoke
    end

    desc 'Run the test suite in Jenkins CI, including test coverage, style check and vulnerability scan'
    task ci: %w[environment ci:setup:rspec cal:test:coverage rubocop brakeman]
  end
end
