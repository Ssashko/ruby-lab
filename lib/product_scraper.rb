require 'httparty'
require 'nokogiri'
require 'json'
require 'fileutils'
require 'sidekiq'
require 'redis'

module MyApplicationCoolPeppers
  class ProductScraper
    attr_reader :config

    def initialize(config)
      @config = config
      ensure_output_directory
    end

    def parse
      LoggerManager.log_info("Starting product scraping")
      url = @config.dig('web_scraping', 'start_page')
      
      unless url
        LoggerManager.log_error("Missing start_page URL in configuration")
        return []
      end

      products = fetch_products(url)
      save_to_json(products)
      products
    rescue StandardError => e
      LoggerManager.log_error("Error during product scraping: #{e.message}")
      []
    end

    private

    def fetch_products(url, page_number = 3)
      redis = Redis.new
      redis.flushdb # Clear any leftover data from previous runs
      LoggerManager.log_info("Starting to fetch products from #{url}")

      jids = []
      for i in 1..page_number
        jid = ProductScraperWorker.perform_async(url, i)
        jids << jid
      end

      loop do
        done = jids.all? { |jid| redis.get("job:#{jid}:done") }
        break if done
        sleep(1)
      end

      all_products = []
      for i in 1..page_number
        key = "products:#{i}"
        products_json = redis.get(key)
        next unless products_json

        all_products.concat(JSON.parse(products_json))
      end

      LoggerManager.log_info("Finished fetching products. Total products: #{all_products.size}")
      all_products
    end

    def save_to_json(products)
      return if products.empty?

      output_path = @config.dig('web_scraping', 'output_file_path') || './output/data.json'
      
      begin
        products_json = JSON.pretty_generate(products)
        File.write(output_path, products_json)
        LoggerManager.log_info("Successfully saved #{products.size} products to #{output_path}")
      rescue StandardError => e
        LoggerManager.log_error("Error saving to JSON: #{e.message}")
      end
    end

    def ensure_output_directory
      output_path = @config.dig('web_scraping', 'output_file_path') || './output/data.json'
      dir_path = File.dirname(output_path)
      
      unless Dir.exist?(dir_path)
        FileUtils.mkdir_p(dir_path)
        LoggerManager.log_info("Created output directory: #{dir_path}")
      end
    end
  end

  class ProductScraperWorker
    include Sidekiq::Worker

    def perform(url, page_number)
      redis = Redis.new
      LoggerManager.log_info("Starting to fetch products from #{url}")

      current_page_url = "#{url}/page=#{page_number}"
      LoggerManager.log_info("Fetching products from: #{current_page_url}")

      begin
        response = HTTParty.get(current_page_url)
        
        unless response.success?
          LoggerManager.log_error("Failed to fetch page #{page_number}. Status code: #{response.code}")
          return
        end

        products = parse_products(response.body)
        redis.set("products:#{page_number}", products.to_json)
        redis.set("job:#{jid}:done", true)

        LoggerManager.log_info("Successfully parsed #{products.size} products from page #{page_number}")
      rescue HTTParty::Error => e
        LoggerManager.log_error("HTTP request failed: #{e.message}")
      rescue StandardError => e
        LoggerManager.log_error("Error fetching products: #{e.message}")
      end
    end

    private

    def parse_products(body)
      parsed_page = Nokogiri::HTML(body)
      products = []
      
      product_items = parsed_page.css('.products__item_inner')
      product_items.each do |item|
        begin
          product_data = extract_product_data(item)
          products << product_data if product_data
        rescue StandardError => e
          LoggerManager.log_error("Error parsing product: #{e.message}")
          next
        end
      end
    
      products
    end

    def extract_product_data(item)
      product_link = item.at_css('.products__item_caption a')&.[]('href')
      product_title = item.at_css('.products__item_caption a')&.[]('title')
      price_wrapper = item.at_css('.products__item_price_wrapper > div')
      product_price = price_wrapper&.text&.strip&.split(' ')&.first
    
      image_element = item.at_css('.products__item_thumb_wrap a img')
      image_path = extract_image_path(image_element)
    
      cashback = item.at_css('.products__item_footer .products__item_cashback span')&.text&.strip&.split(' ')&.first
    
      return nil unless product_link && product_title

      {
        link: product_link,
        title: product_title,
        price: product_price,
        image_path: image_path,
        cashback: cashback,
        scraped_at: Time.now.utc.iso8601
      }
    end

    def extract_image_path(image_element)
      return nil unless image_element
      
      image_path = image_element['src']
      if image_path&.include?('data:image') && image_element['data-src']
        image_path = image_element['data-src']
      end
      image_path
    end
  end
end
