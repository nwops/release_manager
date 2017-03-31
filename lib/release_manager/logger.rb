require 'logger'

module ReleaseManager
  module Logger
    def logger
      unless @logger
        @logger = Logger.new(STDOUT)
        @logger.log_level = log_level
      end
      @logger
    end

    def log_level
      level = ENV['LOG_LEVEL'].downcase if ENV['LOG_LEVEL']
      case level
        when 'warn'
          Logger::Severity::WARN
        when 'debug'
          Logger::Severity::DEBUG
        when 'info'
          Logger::Severity::INFO
        when 'error'
          Logger::Severity::ERROR
        else
          Logger::Severity::INFO
      end
    end
  end
end