module Docker
  class Secret
    class << self
      def setup_environment!(fileglob = '/run/secrets/*')
        Dir[fileglob].each do |filepath|
          secret = File.read(filepath)
          secret_name = File.basename(filepath)
          ENV[secret_name] = secret unless secret.empty?
        end
      end
    end
  end
end
