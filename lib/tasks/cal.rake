require 'ci/reporter/rake/rspec'
require 'rubocop/rake_task'

# Configure CI::Reporter report generation
ENV['GENERATE_REPORTS'] ||= 'true'
ENV['CI_REPORTS'] = 'tmp/reports/specs'

namespace :cal do
  namespace :test do
    desc 'Run all specs in spec directory, with coverage'
    task :coverage do
      ENV['COVERAGE'] ||= 'true'
      Rake::Task[:spec].invoke
    end

    desc 'Run rubocop with HTML output'
    RuboCop::RakeTask.new(:rubocop) do |cop|
      cop.formatters = ['html']
      cop.options = ['--out', 'tmp/reports/rubocop/index.html']
    end

    desc 'Run the test suite in Jenkins CI (including test coverage)'
    task ci: %w[environment ci:setup:rspec cal:test:coverage]
  end
end
