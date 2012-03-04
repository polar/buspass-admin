require "carrierwave/orm/mongomapper"

class Network
  include MongoMapper::Document

  key :name,        String #, :unique => true
  key :description, String
  key :mode,        String # :planning, :testing, :retired, :actives
  key :file_path,   String

  key :processing_lock,     MuniAdmin, :default => nil
  key :processing_progress, Float, :default => 0.0
  key :processing_errors,   Array
  key :processing_log,      Array

  key :processing_started_at,   Time
  key :processing_completed_at, Time

  belongs_to  :municipality

  many :routes, :dependent => :destroy
  many :services

  # This field is where the zipfile gets uploaded. We need to
  # move it to a more permanent place..The Controller will
  # move this to file.
  mount_uploader :upload_file, NetworkFileUploader

  timestamps!

  def self.create_indexes
    self.ensure_index(:name, :unique => true)
  end

  attr_accessible :name, :mode, :municipality, :routes, :file_path, :upload_file, :upload_file_cache

  def route_count
    routes.count
  end
  def services
    routes.map {|r| r.services}.reduce([]) {|v,x| v + x}
  end
  def vehicle_journey_count
    services.map  {|r| r.vehicle_journeys.count }.reduce(0) {|v,x| v + x}
  end
  def service_count
     routes.map {|r| r.services.count }.reduce(0) {|v,x| v + x}
  end
  def delete_routes
    routes.each { |x| x.destroy }
  end
end