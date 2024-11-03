require_relative 'my_application_coolpeppers'
require_relative 'app_config_loader'
require_relative 'item'
require_relative 'cart'

AppConfigLoader.load_libs(File.join(__dir__))

config_data = AppConfigLoader.config(File.join(__dir__, '../config/default_config.yaml'), File.join(__dir__, '../config'))
AppConfigLoader.pretty_print_config_data(config_data)

MyApplicationCoolPeppers::LoggerManager.initialize_logger(config_data['logging'])

start_url = config_data['web_scraping']['start_page']
products = MyApplicationCoolPeppers::ProductScraper.fetch_products(start_url)

if products.any?
  output_path = File.join(__dir__, '../output/data.json')
  MyApplicationCoolPeppers::ProductScraper.save_to_json(products, output_path)
  MyApplicationCoolPeppers::LoggerManager.log_processed_file("Products saved to data.json")
else
  MyApplicationCoolPeppers::LoggerManager.log_error("No products found or failed to fetch data.")
end


fake_item = MyApplicationCoolPeppers::Item.generate_fake

if fake_item
  puts fake_item.info
  puts "Hash Code: #{fake_item.hash_code}"
end

cart = MyApplicationCoolPeppers::Cart.new

cart.generate_test_items(5)

cart.show_all_items

cart.save_to_file('items.txt')
cart.save_to_json('items.json')
cart.save_to_csv('items.csv')
cart.save_to_yml('yml_items')

new_item = MyApplicationCoolPeppers::Item.new(
  link: "http://example.com/new_item",
  title: "New Item",
  price: 29.99,
  image_path: "new_item.jpg",
  cashback: 0.10
)
cart.add_item(new_item)

cart.show_all_items

cart.remove_item(new_item)

cart.show_all_items

cart.delete_items
cart.show_all_items
