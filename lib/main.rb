require_relative 'engine'
require_relative 'logger_manager'
require_relative 'archive_sender'

config_file_path = File.join(__dir__, '../config/default_config.yaml')
config_directory = File.join(__dir__, '../config')

begin
  MyApplicationCoolPeppers::LoggerManager.initialize_logger

  engine = MyApplicationCoolPeppers::Engine.new(config_file_path, config_directory)
  
  engine.configurator.configure({
    run_website_parser: 1,
    run_save_to_mongodb: 1,
    run_save_to_json: 1,
    run_save_to_yaml: 1,
    run_save_to_sqlite: 1,
    run_save_to_mongodb: 1
  })
  
  engine.run

  archive_path = MyApplicationCoolPeppers::ArchiveSender.create_archive_from_output
  MyApplicationCoolPeppers::ArchiveSender.new.perform(archive_path, 'marianchuk.oleksandr@chnu.edu.ua')  
rescue StandardError => e
  error_message = "An error occurred: #{e.message}"
  puts error_message
  MyApplicationCoolPeppers::LoggerManager.log_error(error_message)
end
