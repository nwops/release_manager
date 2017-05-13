require 'logger'

module ReleaseManager
  module Logger
    def logger
      unless @logger
        @logger = ::Logger.new(STDOUT)
        @logger.level = log_level
        @logger.progname = 'ReleaseManager'
        @logger.formatter = proc do |severity, datetime, progname, msg|
          "#{severity} - #{progname}: #{msg}\n".send(color(severity))
        end
      end
      @logger
    end

    def color(severity)
      case severity
      when ::Logger::Severity::WARN, 'WARN'
        :yellow
      when ::Logger::Severity::INFO, 'INFO'
        :green
      when ::Logger::Severity::FATAL, 'FATAL'
        :fatal
      when ::Logger::Severity::ERROR, 'ERROR'
        :fatal
      when ::Logger::Severity::DEBUG, 'DEBUG'
        :green
      else
        :green
      end
    end

    def log_level
      level = ENV['LOG_LEVEL'].downcase if ENV['LOG_LEVEL']
      case level
        when 'warn'
          ::Logger::Severity::WARN
        when 'fatal'
          ::Logger::Severity::FATAL
        when 'debug'
          ::Logger::Severity::DEBUG
        when 'info'
          ::Logger::Severity::INFO
        when 'error'
          ::Logger::Severity::ERROR
        else
          ::Logger::Severity::INFO
      end
    end
  end
end