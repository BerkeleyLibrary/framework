# ------------------------------------------------------------
# Rails

require File.expand_path('config/application', __dir__)
Rails.application.load_tasks

# ------------------------------------------------------------
# Setup

desc 'Set up DB, precompile assets'
task setup: %w[db:await db:setup assets:precompile]

# ------------------------------------------------------------
# Check (setup + coverage)

desc 'Set up, check test coverage'
multitask check: %w[setup coverage]

# ------------------------------------------------------------
# Defaults

# clear rspec/rails default :spec task
Rake::Task[:default].clear if Rake::Task.task_defined?(:default)

desc 'Set up, run tests, check code style, check test coverage, check for vulnerabilities'
task default: %i[check rubocop brakeman bundle:audit]
