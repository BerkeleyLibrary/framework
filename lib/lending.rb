Dir.glob(File.expand_path('lending/*.rb', __dir__)).sort.each(&method(:require))
