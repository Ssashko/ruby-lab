require_relative 'my_application_coolpeppers'
require_relative 'app_config_loader'

AppConfigLoader.load_libs(File.join(__dir__))

config_data = AppConfigLoader.config(File.join(__dir__, '../config/default_config.yaml'), File.join(__dir__, '../config'))

AppConfigLoader.pretty_print_config_data(config_data)

MyApplicationCoolPeppers::LoggerManager.initialize_logger(config_data['logging'])

products = MyApplicationCoolPeppers::ProductScraper.fetch_products(config_data['web_scraping']['start_page'])
puts products

if products.any?
  MyApplicationCoolPeppers::ProductScraper.save_to_json(products, File.join(__dir__, '../output/data.json'))
  MyApplicationCoolPeppers::LoggerManager.log_processed_file("Products saved to data.json")
else
  MyApplicationCoolPeppers::LoggerManager.log_error("No products found or failed to fetch data.")
end
