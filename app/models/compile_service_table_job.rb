require "zip/zip"
require "carrierwave"
require 'carrierwave/uploader/proxy'
require 'carrierwave/orm/mongomapper'

class CompileServiceTableJob < Struct.new(:database, :network)

  def logger
    Rails.logger
  end

  def say(text, level = Logger::INFO)
    text = "[Compile Service Table] #{text}"
    puts text unless @quiet
    logger.add level, "#{Time.now.strftime('%FT%T%z')}: #{text}" if logger
  end

  def perform
    MongoMapper.database = database
    say "Job Started. using DB #{MongoMapper.database.name}"
    say "Network.id #{network.id}"
    say "Network.file #{network.file_path}"
    # Since we were deserialized network is only an instantiation of Network
    # with its id. We need to retrieve it from the DB.
    net = Network.find(network.id)

    # Start processing anew
    net.processing_started_at = Time.now
    net.processing_errors = []
    net.processing_log = []
    net.save

    if !net.file_path || !File.exists?(net.file_path)
      net.processing_errors << "Failed to get zip file"
      raise "No file.: #{net.inspect} DB==#{MongoMapper.database.name}"
    end

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
  ensure
    say "Ending Job"
    #raise "network #{net} id #{id} DB=#{MongoMapper.database.name} #{Network.find(id).file} #{Network.find(id).processing_lock}" if net == nil
    net.processing_lock = nil
    net.processing_completed_at = Time.now
    net.save
  end

  private

  def unzip(zip, unzip_dir, remove_after = false)
    Zip::ZipFile.open(zip) do |zip_file|
      zip_file.each do |f|
        f_path=File.join(unzip_dir, f.name)
        FileUtils.mkdir_p(File.dirname(f_path))
        zip_file.extract(f, f_path) # unless File.exist?(f_path)
      end
    end
    FileUtils.rm(zip) if remove_after
  end

end