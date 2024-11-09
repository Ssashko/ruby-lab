require 'yaml'
require 'fileutils'
require_relative 'app_config_loader'
require_relative 'logger_manager'
require_relative 'product_scraper'
require_relative 'cart'
require_relative 'item'
require_relative 'configurator'

module MyApplicationCoolPeppers
  class Engine
    attr_accessor :config
    attr_reader :configurator

    def initialize(config_file_path, config_directory)
      @config = load_all_configs(config_file_path, config_directory)
      @configurator = Configurator.new
      @cart = Cart.new
      initialize_logging
      LoggerManager.log_info("Engine initialized successfully")
    end

    def initialize_logging
      LoggerManager.initialize_logger(@config['logging'] || {})
    end

    def load_all_configs(main_config_path, config_directory)
      main_config = AppConfigLoader.config(main_config_path, config_directory)
      main_config.merge({
        'web_scraping' => load_yaml_config(File.join(config_directory, 'web_parser.yaml'))&.fetch('web_scraping', {}),
      })
    end

    def load_yaml_config(path)
      if File.exist?(path)
        YAML.load_file(path)
      else
        LoggerManager.log_warn("Config file not found: #{path}")
        {}
      end
    rescue StandardError => e
      LoggerManager.log_error("Error loading config #{path}: #{e.message}")
      {}
    end

    def run
      LoggerManager.log_info("Starting engine run")
      begin
        validate_config
        run_configured_methods
        save_cart_data
        LoggerManager.log_info("Engine run completed successfully")
      rescue StandardError => e
        LoggerManager.log_error("Engine run failed: #{e.message}")
        raise
      end
    end

    def validate_config
      LoggerManager.log_info("Validating configuration")
      required_configs = ['web_scraping']
      
      missing_configs = required_configs.select { |config| @config[config].nil? || @config[config].empty? }
      if missing_configs.any?
        error_message = "Missing required configurations: #{missing_configs.join(', ')}"
        LoggerManager.log_error(error_message)
        raise StandardError, error_message
      end

      LoggerManager.log_info("Configuration validation successful")
    end

    def run_configured_methods
      LoggerManager.log_info("Starting to execute configured methods")

      configurator.config.each do |method_name, should_run|
        next unless should_run == 1

        begin
          LoggerManager.log_info("Attempting to execute method: #{method_name}")
          send(method_name) if respond_to?(method_name, true)
          LoggerManager.log_info("Method #{method_name} executed successfully")
        rescue NoMethodError => e
          LoggerManager.log_error("Method #{method_name} not found: #{e.message}")
        rescue StandardError => e
          LoggerManager.log_error("Error executing #{method_name}: #{e.message}")
        end
      end
    end

    def run_website_parser
      LoggerManager.log_info("Starting website parser")
      scraper = ProductScraper.new(@config)
      parsed_results = scraper.parse
      
      parsed_results.each do |item_data|
        item = Item.new(**item_data)
        @cart.add_item(item)
      end
      
      LoggerManager.log_info("Website parsing completed. Added #{parsed_results.size} products to cart")
    end

    def save_cart_data
      save_directory = @config['output_directory'] || './output'
      FileUtils.mkdir_p(save_directory)
    
      @cart.save_to_json(File.join(save_directory, 'cart.json'))
      @cart.save_to_csv(File.join(save_directory, 'cart.csv'))
      @cart.save_to_yml(File.join(save_directory, 'yml_items'))
      @cart.save_images(File.join(save_directory, 'images'), 10)
      @cart.save_to_mongodb()
      sqlite_config = @config['database_config']['database_config']['sqlite_database']
      @cart.save_to_sqlite(sqlite_config['db_file'])
    
      LoggerManager.log_info("All selected cart data saved")
    end    
  end
end
