require 'yaml'

module MyApplicationCoolPeppers
  class AppConfigLoader
    def self.config(config_file_path, config_directory)
      begin
        config = YAML.load_file(config_file_path)
        
        Dir[File.join(config_directory, '*.yaml')].each do |file|
          next if file == config_file_path # Skip the main config file
          
          config_name = File.basename(file, '.yaml')
          additional_config = YAML.load_file(file)
          config[config_name] = additional_config
        end
        
        config
      rescue Errno::ENOENT => e
        raise ConfigurationError, "Configuration file not found: #{e.message}"
      rescue Psych::SyntaxError => e
        raise ConfigurationError, "Invalid YAML syntax in configuration: #{e.message}"
      rescue StandardError => e
        raise ConfigurationError, "Error loading configuration: #{e.message}"
      end
    end
  end

  class ConfigurationError < StandardError; end
end
