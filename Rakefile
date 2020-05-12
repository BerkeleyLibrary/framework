# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require_relative 'config/application'

Rails.application.load_tasks

begin
  require 'rspec/core/rake_task'
  RSpec::Core::RakeTask.new(:spec)
rescue LoadError
  # don't care, gem only installed in dev/test
end

begin
  require 'rubocop/rake_task'
  desc 'Run rubocop with HTML output'
  RuboCop::RakeTask.new(:rubocop) do |cop|
    cop.formatters = %w[html]
    cop.options = %w[--out tmp/rubocop/index.html]
  end
rescue LoadError
  # don't care, gem only installed in dev/test
end

if ENV['CI'].present?
  ENV['RAILS_ENV'] = 'test'
  ENV['COVERAGE'] ||= 'true'

  multitask setup: %w[assets:precompile]
  multitask specs: %w[brakeman bundle:audit rubocop spec]

  task(:default).clear
  task default: %w[specs]
end
