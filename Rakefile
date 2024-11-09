require 'rake'
require 'yaml'

task :run_main do
  begin
    puts "Running the application"

    require_relative 'lib/main'
  rescue StandardError => e
    puts "An error occurred: #{e.message}"
  end
end
