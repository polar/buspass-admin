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

  attr_accessor :network

  def master
    network.master
  end

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
        File.open(File.join(Rails.root, "log", "service_table.log"), "a+"))
  end

  def say(text, level = Logger::INFO)
    if network.nil?
      text = "[Compile Service Table] #{text}"
    else
      text = "[CST #{master.name}:#{network.name}] #{text}"
    end
    puts text unless @quiet
    logger.add level, "#{Time.now.strftime('%FT%T%z')}: #{text}" if logger
  end

  # If we loose it, we stop.
  def find_service_table_job
    self.service_table_job = ServiceTableJob.find(service_table_job_id)
  end

  def enqueue(job)
    say "Queued: Network.id #{network_id} token #{token}"
    network = Network.find(network_id)
    network.processing_job = job
    network.save
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
    self.network = Network.find(network_id)
    if (find_service_table_job.nil? || network.nil?)
      say "Network job aborted."
      return
    end
    # We need to reload because we may have gotten this out of the IdentityMap?
    network.reload
    check!("Perform")

    if network.processing_token != token
      # This job is currently being processed by some other entity.
      # Don't touch, just leave
      dont_touch = true
      check!("Conflict")
      return
    end

    # Start processing anew
    network.processing_started_at = Time.now
    network.processing_errors = []
    network.processing_log = []
    network.save

    if !network.upload_file || !network.upload_file.present?
      network.processing_errors << "Failed to get zip file"
      raise "No file at '#{network.upload_file.url}'"
    end

    dir = Dir.mktmpdir()

    begin
      network.upload_file.cache_stored_file!

      # WTF: upload_file.filename is only something after the cache_stored_file! call
      say "Unzipping #{network.upload_file.filename} as local #{network.upload_file.full_cache_path}"
      unzip(network.upload_file.full_cache_path, dir)
    rescue Exception => boom
      say "Bad unzip"
      network.processing_errors << "Failed to unzip uploaded file."
      raise "Unzip #{boom}"
      return
    end

    check!("Processing")

    say "Begin process network"
    ServiceTable.processNetwork(network, dir)
    say "End process network"

    check!("Finished")
  rescue Exception => boom
    say "#{boom}"

  ensure
    unless dont_touch
      say "Ending Job: Network.id #{network_id} token #{token}"
      network.processing_lock = nil
      network.processing_job = nil
      network.processing_completed_at = Time.now
      network.processing_token = nil
      network.save
    else
      say "Ignoring Job: Network.id #{network_id} token #{token} One is currently running"
    end
    if find_service_table_job
      service_table_job.destroy
    end
  end

  private

  def unzip(zip, unzip_dir)
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