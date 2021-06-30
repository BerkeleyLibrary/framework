require 'lending'

namespace :lending do
  desc 'Creates tiled TIFFs from an image or list of images.'
  task :tileize do
    Lending::Tileizer.tileize_env
  rescue StandardError
    puts 'Usage: rake INFILE=<infile> OUTFILE=<outfile> [SKIP_EXISTING=skip] lending:tileize'
    raise
  end
end
