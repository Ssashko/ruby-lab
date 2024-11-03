require 'httparty'
require 'nokogiri'
require 'json'

module MyApplicationCoolPeppers
  class ProductScraper
    def self.fetch_products(url, max_pages = 3)
      page_number = 1
      all_products = []

      loop do
        current_page_url = "#{url}/page=#{page_number}"
        puts "Fetching products from: #{current_page_url}"

        response = HTTParty.get(current_page_url)
        if response.code != 200
          puts "Failed to fetch page #{page_number}. Status code: #{response.code}"
          break
        end

        products = parse_products(response.body)
        break if products.empty?

        all_products.concat(products)
        
        puts "Page #{page_number} products: #{products}"

        break if page_number > 1 && products.size == all_products[0...all_products.size].size

        page_number += 1
        break if page_number > max_pages
      end

      all_products
    end

    def self.parse_products(body)
      parsed_page = Nokogiri::HTML(body)
      products = []
      product_items = parsed_page.css('.products__item_inner')
    
      product_items.each do |item|
        product_link = item.at_css('.products__item_caption a')['href']
        product_title = item.at_css('.products__item_caption a')['title']
        price_wrapper = item.at_css('.products__item_price_wrapper > div')
        product_price = price_wrapper&.text&.strip&.split(' ')&.first
    
        image_element = item.at_css('.products__item_thumb_wrap a img')
        image_path = image_element['src']
        if image_path.include?('data:image') && image_element['data-src']
          image_path = image_element['data-src']
        end
    
        cashback = item.at_css('.products__item_footer .products__item_cashback span')&.text&.strip&.split(' ')&.first
    
        product_data = {
          link: product_link,
          title: product_title,
          price: product_price,
          image_path: image_path,
          cashback: cashback
        }
    
        products << product_data
      end
    
      products
    end
    

    def self.save_to_json(products, file_path = './output/data.json')
      products_json = products.to_json

      File.open(file_path, 'w') do |f|
        f.write(products_json)
      end
    end
  end
end
