require 'httparty'
require 'nokogiri'
require 'json'

module MyApplicationCoolPeppers
  class ProductScraper
    def self.fetch_products(url)
      response = HTTParty.get(url)

      if response.code == 200
        parse_products(response.body)
      else
        puts "Failed to fetch the page. Status code: #{response.code}"
        []
      end
    end

    def self.parse_products(body)
      parsed_page = Nokogiri::HTML(body)
      products = []
      product_items = parsed_page.css('.products__item_caption')

      product_items.each do |item|
        product_link = item.at_css('a')['href']
        product_title = item.at_css('a')['title']

        price_wrapper = item.at_css('.products__item_price_wrapper > div')
        product_price = price_wrapper&.text&.strip&.split(' ')&.first

        product_data = {
          link: product_link,
          title: product_title,
          price: product_price
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
