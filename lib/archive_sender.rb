require 'zip'
require 'sidekiq'
require 'pony'

module MyApplicationCoolPeppers
  class ArchiveSender
    include Sidekiq::Worker

    def perform(archive_path, recipient_email)
      send_archive(archive_path, recipient_email)
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
      Pony.mail({
        to: recipient_email,
        subject: 'Your archived data',
        body: 'Please find the attached archive.',
        attachments: { File.basename(archive_path) => File.read(archive_path) },
        via: :smtp,
        via_options: {
          address: 'smtp.your-email-provider.com',
          port: '587',
          user_name: 'your_username',
          password: 'your_password',
          authentication: :plain,
          domain: 'your-domain.com'
        }
      })
      puts "Archive sent to: #{recipient_email}"
    end
  end
end
