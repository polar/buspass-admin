require "zipruby"
require "fileutils"
require "carrierwave"
require 'carrierwave/uploader/proxy'
require 'carrierwave/orm/mongomapper'

##
# This class represents a serializable object that gets passed to
# Delayed Job.
#
class CompileServiceTableJob < Struct.new(:network_id)

  def logger
    Rails.logger
  end

  def say(text, level = Logger::INFO)
    text = "[Compile Service Table] #{text}"
    puts text unless @quiet
    logger.add level, "#{Time.now.strftime('%FT%T%z')}: #{text}" if logger
  end

  def perform
    say "Network.id #{network_id}"
    # Since we were deserialized network is only an instantiation of Network
    # with its id. We need to retrieve it from the DB.
    net = Network.find(network_id)
    say "Network.file #{net.file_path}"

    if !net.file_path || !File.exists?(net.file_path)
      net.processing_errors << "Failed to get zip file"
      raise "No file.: #{net.inspect}"
    end

    # Start processing anew
    net.processing_started_at = Time.now
    net.processing_errors = []
    net.processing_log = []
    net.save

    dir = Dir.mktmpdir()

    begin
      say "Begin Unzip"
      zipfile_path = net.file_path
      unzip(zipfile_path, dir)
    rescue Exception => boom
      say "Bad unzip"
      net.processing_errors << "Failed to unzip uploaded file."
      raise "Unzip #{boom}"
      return
    end

    say "Begin rebuild"
    ServiceTable.processDirectory(net, dir)
    say "End Rebuild"

    begin
      say "Creating Zip file #{net.file_path}"
      zip(net, net.file_path, dir)
      say "Created Zip file #{net.file_path}"
      say "Removing Tmp Dir #{dir}"
     # FileUtils.rm_rf(dir)
    rescue Exception => boom2
      say "Bad zip"
      net.processing_errors << "Failed to zip resultant directory #{dir}"
      raise "Zip #{boom2}"
    end

  ensure
    say "Ending Job"
    net.processing_lock = nil
    net.processing_completed_at = Time.now
    net.save
  end

  private

  def unzip(zip, unzip_dir, remove_after = false)
    Zip::Archive.open(zip) do |zip_file|
      zip_file.each do |f|
        f_path = File.join(unzip_dir, f.name)
        if f.directory?
          FileUtils.mkdir_p(File.dirname(f_path))
        else
          FileUtils.mkdir_p(File.dirname(f_path))
          File.open(f_path, "wb") do |w|
            w << f.read
          end
        end
      end
    end
    FileUtils.rm(zip) if remove_after
  end

  def zip(network, zip, dir)
    say "ZIP IT #{dir}"
    Zip::Archive.open(zip, Zip::CREATE | Zip::TRUNC) do |zip_file|
      Dir.glob("#{dir}/**/*").each do |path|
        zpath = path.sub(/^#{dir}/, network.name)
        say "zipping #{zpath} <- #{path}"
        if File.directory?(path)
          zip_file.add_dir(zpath)
        else
          zip_file.add_file(zpath, path)
        end
      end
    end
  end

end