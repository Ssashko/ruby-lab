require 'logger'

module MyApplicationCoolPeppers
  class LoggerManager
    class << self
      attr_reader :logger

      def initialize_logger(config)
        log_directory = config['directory'] || './logs'
        log_level = config['level'] || 'DEBUG'
        log_file = config['files']['application_log'] || 'application.log'

        Dir.mkdir(log_directory) unless Dir.exist?(log_directory)

        @logger = Logger.new(File.join(log_directory, log_file))
        @logger.level = Logger.const_get(log_level)
      end

      def log_processed_file(message)
        @logger.info(message)
      end

      def log_error(message)
        @logger.error(message)
      end
    end
  end
end
