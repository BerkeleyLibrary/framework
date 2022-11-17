require 'spec_helper'

describe 'Gemfile.lock' do
  attr_reader :parser

  before do
    lockfile_path = File.expand_path('../Gemfile.lock', __dir__)
    expect(File.exist?(lockfile_path)).to eq(true), "Gemfile.lock not found in #{lockfile_path}"

    lockfile = File.read(lockfile_path)
    @parser = Bundler::LockfileParser.new(lockfile)
  end

  describe 'PLATFORMS' do
    let(:required_platforms) { ['x86_64-linux'] }

    it 'includes all required platforms' do
      platforms = parser.platforms
      platform_names = platforms.map(&:to_s)

      aggregate_failures do
        required_platforms.each do |pf_name|
          msg = "Platform #{pf_name.inspect} not in Gemfile.lock; run `bundle lock --add-platform #{pf_name}`"
          expect(platform_names).to include(pf_name), msg
        end
      end
    end
  end
end
