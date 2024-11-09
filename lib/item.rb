require 'faker'
require_relative 'logger_manager'

module MyApplicationCoolPeppers
  class Item
    include Comparable

    attr_accessor :link, :title, :price, :image_path, :cashback, :scraped_at

    def initialize(link: "https://example.com", title: "No Title", price: 0.0, image_path: "/images/default.jpg", cashback: "0", scraped_at: nil)
      @link = link
      @title = title
      @price = price
      @image_path = image_path
      @cashback = cashback
      @scraped_at = scraped_at || Time.now.utc.iso8601
      LoggerManager.log_processed_file("Initialized Item: #{self}")
    rescue StandardError => e
      LoggerManager.log_error("Error initializing Item: #{e.message}")
    end

    def to_s
      "Item: #{title}, Price: #{price}, Cashback: #{cashback}, Link: #{link}, Image: #{image_path}, Scraped At: #{scraped_at}"
    end

    def to_h
      {
        link: @link,
        title: @title,
        price: @price,
        image_path: @image_path,
        cashback: @cashback,
        scraped_at: @scraped_at
      }
    end

    def <=>(other)
      self.price <=> other.price
    end

    def self.generate_fake
      item = new(
        link: Faker::Internet.url,
        title: Faker::Commerce.product_name,
        price: Faker::Commerce.price(range: 10.0..100.0),
        image_path: Faker::LoremFlickr.image(size: "50x60"),
        cashback: "#{rand(1..10)}%",
        scraped_at: Time.now.utc.iso8601
      )
      LoggerManager.log_processed_file("Generated fake Item: #{item}")
      item
    end
  end
end
