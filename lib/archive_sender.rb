require 'zip'
require 'sidekiq'
require 'pony'
require 'yaml'

module MyApplicationCoolPeppers
  class ArchiveSender
    include Sidekiq::Worker

    CONFIG = YAML.load_file(File.join(__dir__, '../config/default_config.yaml'))['default']

    def perform(archive_path, recipient_email)
      send_archive(archive_path, recipient_email)
    end

    def self.create_archive_from_output
      output_directory = CONFIG['output_directory']
      archive_directory = CONFIG['archive_directory']
      
      Dir.mkdir(archive_directory) unless Dir.exist?(archive_directory)

      archive_path = File.join(archive_directory, "output_archive_#{Time.now.strftime('%Y%m%d%H%M%S')}.zip")
      file_paths = Dir.glob("#{output_directory}/**/*").select { |file| File.file?(file) }

      create_archive(file_paths, archive_path)
      archive_path
    end

    def self.create_archive(file_paths, archive_path)
      Zip::File.open(archive_path, Zip::File::CREATE) do |zipfile|
        file_paths.each do |file|
          zipfile.add(File.basename(file), file) if File.exist?(file)
        end
      end
      puts "Files archived to: #{archive_path}"
    end

    private

    def send_archive(archive_path, recipient_email)
      email_settings = CONFIG['email']
      smtp_settings = email_settings['smtp']
      # './output/cart.csv'

      Pony.mail({
        to: recipient_email,
        from: email_settings['from'],
        subject: 'Your archived data',
        body: 'Please find the attached archive.',
        attachments: { File.basename('./output/cart.csv') => File.read('./output/cart.csv') },
        via: :smtp,
        via_options: {
          address: smtp_settings['address'],
          port: smtp_settings['port'],
          user_name: smtp_settings['user_name'],
          password: smtp_settings['password'],
          authentication: smtp_settings['authentication'],
          domain: smtp_settings['domain']
        }
      })
      puts "Archive sent to: #{recipient_email}"
    end
  end
end
