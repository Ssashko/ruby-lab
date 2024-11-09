require 'logger'
require 'fileutils'

module MyApplicationCoolPeppers
  class LoggerManager
    class << self
      attr_accessor :logger

      def initialize_logger(config = {})
        log_dir = config['log_directory'] || 'logs'
        FileUtils.mkdir_p(log_dir)
        
        @logger = Logger.new(File.join(log_dir, 'application.log'), 'daily')
        @logger.level = get_log_level(config['log_level'])
        @logger.formatter = proc do |severity, datetime, progname, msg|
          "[#{datetime}] #{severity}: #{msg}\n"
        end
      end

      def log_info(message)
        ensure_logger
        @logger.info(message)
      end

      def log_error(message)
        ensure_logger
        @logger.error(message)
        puts "ERROR: #{message}"
      end

      def log_warning(message)
        ensure_logger
        @logger.warn(message)
      end

      def log_debug(message)
        ensure_logger
        @logger.debug(message)
      end

      def log_processed_file(message)
        ensure_logger
        @logger.info("File processed: #{message}")
      end

      private

      def ensure_logger
        initialize_logger unless @logger
      end

      def get_log_level(level)
        case level&.downcase
        when 'debug'
          Logger::DEBUG
        when 'info'
          Logger::INFO
        when 'warn'
          Logger::WARN
        when 'error'
          Logger::ERROR
        else
          Logger::INFO
        end
      end
    end
  end
end