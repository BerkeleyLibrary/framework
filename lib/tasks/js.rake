namespace :js do
  # TODO: clean this up (task class?)
  desc 'check JavaScript syntax, find problems, and enforce code style'
  task :eslint do
    report_path = "artifacts/eslint/index.html"
    FileUtils.rm_f(report_path) # clear out any old report
    FileUtils.mkdir_p(File.dirname(report_path))

    begin
      # Run ESLint and generate HTML report
      cmd_gen_report = %w[npx eslint --format=html app/assets/javascripts]
      sh(*cmd_gen_report, out: report_path, err: File::NULL) do |ok, ps|
        next if ok

        # Run ESLint again, but this time with console output
        cmd_rerun_for_console = cmd_gen_report.reject { |c| c.start_with?('--format') }

        # we pass an empty block so Rake doesn't exit ungracefully when the command fails
        sh(*cmd_rerun_for_console, err: File::NULL) {}

        # now we exit with the original status code
        exit(ps.exitstatus)
      end
    ensure
      puts "ESLint report written to #{report_path}" if File.exist?(report_path)
    end
  end
end
