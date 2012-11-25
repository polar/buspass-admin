require "zipruby"
require "fileutils"
require "logger"
require "carrierwave"
require 'carrierwave/uploader/proxy'
require 'carrierwave/orm/mongomapper'

##
# This class represents a serializable object that gets passed to
# Delayed Job.
#
class CompileServiceTableJob < Struct.new(:network_id, :token, :service_table_job_id)

  def self.to_mongo(value)
    value.nil? ||
        !value.is_a?(self) ?
        value :
        value.to_array_for_mongo
  end

  def to_array_for_mongo
    [network_id, token, service_table_job_id]
  end

  def self.from_mongo(value)
    value.is_a?(self) ? value : CompileServiceTableJob.new(*value)
  end

  attr_accessor :service_table_job

  def logger
    @logger ||= ::ActiveSupport::BufferedLogger.new(
        File.open(File.join(Rails.root, "log", "service_table.log"), "a+")).tap {|l| l.auto_flushing = true }
  end

  def say(text, level = Logger::INFO)
    text = "[Compile Service Table] #{text}"
    puts text unless @quiet
    logger.add level, "#{Time.now.strftime('%FT%T%z')}: #{text}" if logger
  end

  # If we loose it, we stop.
  def find_service_table_job
    self.service_table_job = ServiceTableJob.find(service_table_job_id)
  end

  def enqueue(job)
    say "Queued: Network.id #{network_id} token #{token}"
    net = Network.find(network_id)
    net.processing_job = job
    net.save
    if find_service_table_job
      service_table_job.status!("Enqueued")
    end
  end

  def check!(status)
    if !find_service_table_job || ! Network.find(network_id)
      raise "Abort"
    else
      service_table_job.status!(status)
    end
  end

  def perform
    say "Perform: Network.id #{network_id} token #{token} service_table_job #{service_table_job_id}"
    net = Network.find(network_id)
    if (find_service_table_job.nil? || net.nil?)
      say "Network job aborted."
      return
    end
    check!("Perform")

    say "Network.file #{net.file_path} Network.token #{net.processing_token}"

    if net.processing_token != token
      # This job is currently being processed by some other entity.
      # Don't touch, just leave
      dont_touch = true
      check!("Conflict")
      return
    end

    # Start processing anew
    net.processing_started_at = Time.now
    net.processing_errors = []
    net.processing_log = []
    net.save

    if !net.file_path || !File.exists?(net.file_path)
      net.processing_errors << "Failed to get zip file"
      raise "No file at '#{net.file_path}'"
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

    check!("Processing")

    say "Begin process network"
    ServiceTable.processNetwork(net, dir)
    say "End process network"

    check!("Finished")

    begin
      say "Creating Zip file #{net.file_path}"
      zip(net, net.file_path, dir)
      # net.processing_log << "Result File is prepared and zipped at #{net.file_path}."
      say "Created Zip file #{net.file_path}"
      say "Removing Tmp Dir #{dir}"
     # FileUtils.rm_rf(dir)
    rescue Exception => boom2
      say "Bad zip"
      net.processing_errors << "Failed to zip resultant directory #{dir}"
      raise "Zip #{boom2}"
    end
  rescue Exception => boom
    say "#{boom}"

  ensure
    unless dont_touch
      say "Ending Job: Network.id #{network_id} token #{token}"
      net.processing_lock = nil
      net.processing_job = nil
      net.processing_completed_at = Time.now
      net.save
    else
      say "Ignoring Job: Network.id #{network_id} token #{token} One is currently running"
    end
    if find_service_table_job
      service_table_job.destroy
    end
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