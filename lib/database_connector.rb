require 'yaml'
require 'sqlite3'
require 'mongo'
require_relative 'logger_manager'

module MyApplicationCoolPeppers
  class DatabaseConnector
    SUPPORTED_DATABASES = ['sqlite', 'mongodb'].freeze
    attr_reader :db, :config

    def initialize(config_path)
      @config_path = config_path
      load_config
      validate_config
    end

    def connect_to_database
      LoggerManager.log_info("Attempting to connect to #{@config['database_config']['database_type']} database")
      
      case @config['database_config']['database_type']
      when 'sqlite'
        connect_to_sqlite
      when 'mongodb'
        connect_to_mongodb
      else
        raise ConfigurationError, "Unsupported database type: #{@config['database_config']['database_type']}. Supported types are: #{SUPPORTED_DATABASES.join(', ')}"
      end
      
      LoggerManager.log_info("Successfully connected to #{@config['database_config']['database_type']} database")
    end

    def close_connection
      return unless @db

      case @config['database_config']['database_type']
      when 'sqlite'
        @db.close
      when 'mongodb'
        @db.close
      end
      
      @db = nil
      LoggerManager.log_info("Database connection closed")
    end

    def self.save_to_sqlite(data, database_path)
      raise ArgumentError, "No data provided" if data.nil? || data.empty?
      
      db = SQLite3::Database.new(database_path)
      begin
        columns = data.first.keys
        create_table_sql = "CREATE TABLE IF NOT EXISTS products (#{columns.map { |col| "#{col} TEXT" }.join(', ')})"
        db.execute(create_table_sql)
        
        data.each do |row|
          placeholders = Array.new(columns.size, '?').join(', ')
          insert_sql = "INSERT INTO products (#{columns.join(', ')}) VALUES (#{placeholders})"
          db.execute(insert_sql, row.values)
        end
        
        LoggerManager.log_info("Successfully saved data to SQLite database at #{database_path}")
      rescue SQLite3::Exception => e
        LoggerManager.log_error("Failed to save to SQLite: #{e.message}")
        raise
      ensure
        db.close
      end
    end

    def self.save_to_mongodb(data)
      raise ArgumentError, "No data provided" if data.nil? || data.empty?
      
      config = YAML.load_file('config/database_config.yaml')
      client = Mongo::Client.new(
        config['database_config']['mongodb_database']['uri'],
        database: config['database_config']['mongodb_database']['db_name']
      )
      begin
        collection = client[:products]
        collection.insert_many(data)
        LoggerManager.log_info("Successfully saved data to MongoDB")
      rescue Mongo::Error => e
        LoggerManager.log_error("Failed to save to MongoDB: #{e.message}")
        raise
      ensure
        client.close
      end
    end

    private

    def load_config
      @config = YAML.load_file(@config_path)
      LoggerManager.log_info("Database configuration loaded from #{@config_path}")
    rescue Errno::ENOENT
      error_msg = "Database configuration file not found at #{@config_path}"
      LoggerManager.log_error(error_msg)
      raise ConfigurationError, error_msg
    rescue Psych::SyntaxError => e
      error_msg = "Invalid YAML in database configuration file: #{e.message}"
      LoggerManager.log_error(error_msg)
      raise ConfigurationError, error_msg
    end

    def validate_config
      unless @config && @config['database_config'] && @config['database_config']['database_type']
        error_msg = "Invalid configuration: Missing database_config or database_type. Please check your configuration file."
        LoggerManager.log_error(error_msg)
        raise ConfigurationError, error_msg
      end

      unless SUPPORTED_DATABASES.include?(@config['database_config']['database_type'])
        error_msg = "Unsupported database type: #{@config['database_config']['database_type']}. Supported types are: #{SUPPORTED_DATABASES.join(', ')}"
        LoggerManager.log_error(error_msg)
        raise ConfigurationError, error_msg
      end

      case @config['database_config']['database_type']
      when 'sqlite'
        validate_sqlite_config
      when 'mongodb'
        validate_mongodb_config
      end
    end

    def validate_sqlite_config
      sqlite_config = @config['database_config']['sqlite_database']
      unless sqlite_config && sqlite_config['db_file']
        error_msg = "Invalid SQLite configuration: Missing db_file"
        LoggerManager.log_error(error_msg)
        raise ConfigurationError, error_msg
      end
    end

    def validate_mongodb_config
      mongodb_config = @config['database_config']['mongodb_database']
      unless mongodb_config && mongodb_config['uri'] && mongodb_config['db_name']
        error_msg = "Invalid MongoDB configuration: Missing uri or db_name"
        LoggerManager.log_error(error_msg)
        raise ConfigurationError, error_msg
      end
    end

    def connect_to_sqlite
      sqlite_config = @config['database_config']['sqlite_database']
      database_path = sqlite_config['db_file']
      timeout = sqlite_config['timeout'] || 5000
      
      @db = SQLite3::Database.new(database_path, timeout: timeout)
      @db.results_as_hash = true
    rescue SQLite3::Exception => e
      error_msg = "Failed to connect to SQLite database: #{e.message}"
      LoggerManager.log_error(error_msg)
      raise DatabaseError, error_msg
    end

    def connect_to_mongodb
      mongodb_config = @config['database_config']['mongodb_database']
      @db = Mongo::Client.new(
        mongodb_config['uri'],
        database: mongodb_config['db_name']
      )
    rescue Mongo::Error => e
      error_msg = "Failed to connect to MongoDB: #{e.message}"
      LoggerManager.log_error(error_msg)
      raise DatabaseError, error_msg
    end
  end

  class ConfigurationError < StandardError; end
  class DatabaseError < StandardError; end
end