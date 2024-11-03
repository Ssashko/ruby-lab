require 'json'
require 'csv'
require 'yaml'
require_relative 'logger_manager'

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

    def remove_item(item)
      if @items.delete(item)
        MyApplicationCoolPeppers::LoggerManager.log_processed_file("Removed item: #{item}")
      else
        MyApplicationCoolPeppers::LoggerManager.log_error("Item not found: #{item}")
      end
    end

    def delete_items
      @items.clear
      MyApplicationCoolPeppers::LoggerManager.log_processed_file("Deleted all items from the collection")
    end

    def parameterize(string)
      string.downcase.gsub(/[^a-z0-9]+/, '_').chomp('_')
    end

    def show_all_items
      puts "All items in collection:"
      @items.each { |item| puts item }
    end

    def save_to_file(file_path)
      File.open(file_path, 'w') do |file|
        file.puts @items.map(&:to_s)
      end
      MyApplicationCoolPeppers::LoggerManager.log_processed_file("Saved items to text file: #{file_path}")
    end

    def save_to_json(file_path)
      File.open(file_path, 'w') do |file|
        file.write(JSON.pretty_generate(@items.map(&:to_h)))
      end
      MyApplicationCoolPeppers::LoggerManager.log_processed_file("Saved items to JSON file: #{file_path}")
    end

    def save_to_csv(file_path)
      CSV.open(file_path, 'w') do |csv|
        csv << ['Link', 'Title', 'Price', 'Image Path', 'Cashback']
        @items.each do |item|
          csv << [item.link, item.title, item.price, item.image_path, item.cashback]
        end
      end
      MyApplicationCoolPeppers::LoggerManager.log_processed_file("Saved items to CSV file: #{file_path}")
    end

    def save_to_yml(directory)
      Dir.mkdir(directory) unless Dir.exist?(directory)
      @items.each do |item|
        file_name = parameterize(item.title)
        File.open("#{directory}/#{file_name}.yml", 'w') do |file|
          file.write(item.to_h.to_yaml)
        end
        MyApplicationCoolPeppers::LoggerManager.log_processed_file("Saved item to YAML file: #{directory}/#{file_name}.yml")
      end
    end

    def generate_test_items(count)
      count.times do
        add_item(Item.generate_fake)
      end
      MyApplicationCoolPeppers::LoggerManager.log_processed_file("Generated #{count} test items")
    end

    include Enumerable

    def each(&block)
      @items.each(&block)
    end

    def map(&block)
      @items.map(&block)
    end

    def select(&block)
      @items.select(&block)
    end

    def reject(&block)
      @items.reject(&block)
    end

    def find(&block)
      @items.find(&block)
    end

    def reduce(initial = nil, &block)
      @items.reduce(initial, &block)
    end

    def all?(&block)
      @items.all?(&block)
    end

    def any?(&block)
      @items.any?(&block)
    end

    def none?(&block)
      @items.none?(&block)
    end

    def count(&block)
      @items.count(&block)
    end

    def sort(&block)
      @items.sort(&block)
    end

    def uniq(&block)
      @items.uniq(&block)
    end
  end
end
