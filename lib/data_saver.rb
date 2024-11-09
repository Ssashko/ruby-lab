require 'csv'
require 'json'
require 'yaml'
require 'sqlite3'
require 'mongo'

module MyApplicationCoolPeppers
  class DataSaver
    def self.save_to_csv(data, file_path)
      CSV.open(file_path, 'w') do |csv|
        csv << data.first.keys # Заголовки
        data.each { |row| csv << row.values }
      end
      puts "Data saved to CSV: #{file_path}"
    end

    def self.save_to_json(data, file_path)
      File.write(file_path, JSON.pretty_generate(data))
      puts "Data saved to JSON: #{file_path}"
    end

    def self.save_to_yaml(data, file_path)
      File.write(file_path, data.to_yaml)
      puts "Data saved to YAML: #{file_path}"
    end

    def self.save_to_sqlite(data, db_path, table_name)
      db = SQLite3::Database.new(db_path)
      columns = data.first.keys
      db.execute("CREATE TABLE IF NOT EXISTS #{table_name} (#{columns.join(' TEXT, ')} TEXT)")
      
      data.each do |row|
        placeholders = (["?"] * columns.size).join(", ")
        db.execute("INSERT INTO #{table_name} (#{columns.join(', ')}) VALUES (#{placeholders})", row.values)
      end
      db.close
      puts "Data saved to SQLite: #{db_path}"
    end

    def self.save_to_mongodb(data, collection_name, config)
      client = Mongo::Client.new([ "#{config['host']}:#{config['port']}" ], database: config['database'])
      collection = client[collection_name]
      collection.insert_many(data)
      client.close
      puts "Data saved to MongoDB in collection: #{collection_name}"
    end
  end
end
