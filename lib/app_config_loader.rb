require 'yaml'
require 'erb'
require 'json'

class AppConfigLoader
  SYSTEM_LIBS = ['date']

  def self.config(default_config_path, config_directory)
    config_data = load_default_config(default_config_path)
    Dir.glob(File.join(config_directory, '*.yaml')).each do |file|
      config_data.merge!(load_config(file))
    end

    if block_given?
      yield config_data
    end

    config_data
  end

  def self.pretty_print_config_data(config_data)
    puts JSON.pretty_generate(config_data)
  end

  def self.load_libs(libs_directory)
    SYSTEM_LIBS.each { |lib| require lib }

    loaded_files = []
    Dir.glob(File.join(libs_directory, '*.rb')).each do |file|
      next if loaded_files.include?(file)

      require_relative file
      loaded_files << file
    end
  end

  private

  def self.load_default_config(file_path)
    config_content = File.read(file_path)
    erb_parsed_content = ERB.new(config_content).result
    YAML.safe_load(erb_parsed_content)
  end

  def self.load_config(file_path)
    YAML.load_file(file_path)
  end
end
