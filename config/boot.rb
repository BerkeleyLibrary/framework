ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../Gemfile', __dir__)

require 'bundler/setup' # Set up gems listed in the Gemfile.
require 'bootsnap/setup' # Speed up boot time by caching expensive operations.
#require 'rubygems'  
#require 'rails/commands/server'
#module Rails
#  class Server
#    def default_options
#      super.merge({Port: 3000, Host: '128.32.99.161'})
#    end
#  end
#end
