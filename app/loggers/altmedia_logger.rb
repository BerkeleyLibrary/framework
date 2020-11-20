module AltmediaLogger
  class Logger < Ougai::Logger
    include ActiveSupport::LoggerThreadSafeLevel
    include ActiveSupport::LoggerSilence

    def initialize(*args)
      super
    end

    def create_formatter
      Formatter.new
    end
  end

  class Formatter < Ougai::Formatters::Bunyan
    def initialize(*args)
      super
      after_initialize if respond_to? :after_initialize
    end

    def _call(severity, time, progname, data)
      dump({
        name: progname || @app_name,
        hostname: @hostname,
        pid: $PID,
        level: severity.to_s,
        time: time
      }.merge(data))
    end

  end
end
