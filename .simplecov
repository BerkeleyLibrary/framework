require 'simplecov-rcov'

SimpleCov.start 'rails' do
  add_filter %w( /app/channels/ /bin/ /db/ )
  coverage_dir 'test/reports'
  formatter SimpleCov::Formatter::RcovFormatter
end
