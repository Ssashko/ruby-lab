require 'json'
require 'csv'
require 'yaml'
require 'httparty'
require_relative 'logger_manager'
require_relative 'database_connector'
require_relative 'data_saver'

module MyApplicationCoolPeppers
  class Cart
    attr_accessor :items

    def initialize
      @items = []
      MyApplicationCoolPeppers::LoggerManager.log_processed_file("Initialized Cart with empty items collection")
    end

    def add_item(item)
      @items << item
      MyApplicationCoolPeppers::LoggerManager.log_processed_file("Added item: #{item}")
    end

    def save_to_json(file_path)
      File.open(file_path, 'w') do |file|
        file.write(JSON.pretty_generate(@items.map(&:to_h)))
      end
      MyApplicationCoolPeppers::LoggerManager.log_processed_file("Saved cart to JSON: #{file_path}")
    end

    def save_to_csv(file_path)
      CSV.open(file_path, 'w') do |csv|
        csv << ['Link', 'Title', 'Price', 'Image Path', 'Cashback', 'Scraped At']
        @items.each do |item|
          csv << [item.link, item.title, item.price, item.image_path, item.cashback, item.scraped_at]
        end
      end
      MyApplicationCoolPeppers::LoggerManager.log_processed_file("Saved cart to CSV: #{file_path}")
    end

    def save_to_yml(directory)
      Dir.mkdir(directory) unless Dir.exist?(directory)
      @items.each do |item|
        file_name = item.title.downcase.gsub(/[^a-z0-9]+/, '_').chomp('_')
        File.open("#{directory}/#{file_name}.yml", 'w') do |file|
          file.write(item.to_h.to_yaml)
        end
        MyApplicationCoolPeppers::LoggerManager.log_processed_file("Saved item to YAML file: #{directory}/#{file_name}.yml")
      end
    end

    def save_images(directory, limit = 10)
      Dir.mkdir(directory) unless Dir.exist?(directory)
      @items.first(limit).each do |item|
        next unless item.image_path

        image_data = HTTParty.get(item.image_path).body
        image_name = item.title.downcase.gsub(/[^a-z0-9]+/, '_').chomp('_')
        image_path = File.join(directory, "#{image_name}.jpg")
        
        File.open(image_path, 'wb') { |file| file.write(image_data) }
        MyApplicationCoolPeppers::LoggerManager.log_processed_file("Saved image for item #{item.title} to #{image_path}")
      end
    end

    def save_to_mongodb()
      data = @items.map(&:to_h)
      DatabaseConnector.save_to_mongodb(data)
      MyApplicationCoolPeppers::LoggerManager.log_processed_file("Saved cart to MongoDB")
    end

    def save_to_sqlite(database_path)
      data = @items.map(&:to_h)
      DatabaseConnector.save_to_sqlite(data, database_path)
      MyApplicationCoolPeppers::LoggerManager.log_processed_file("Saved cart to SQLite database: #{database_path}")
    end
  end
end
