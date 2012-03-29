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
  belongs_to  :owner, :class_name => "MuniAdmin"
  belongs_to  :master

  many :routes, :dependent => :destroy
  many :services

  # This field is where the zipfile gets uploaded. We need to
  # move it to a more permanent place..The Controller will
  # move this to file.
  mount_uploader :upload_file, NetworkFileUploader

  timestamps!

  validates_uniqueness_of :name, :scope => [ :master_id, :municipality_id ]

  def self.create_indexes
    self.ensure_index(:name, :unique => true)
  end

  attr_accessible :name, :mode, :municipality

  def copy!(new_municipality)
    network = Network.new(self.attributes)
    network.municipality = new_municipality
    # May have to change name.
    if network.save
      routes = {}
      services = []
      vehicle_journeys = []
      begin
        for s in self.services
          if routes[s.route.code] != nil
            routes[s.route.code] = route
          end
          route = routes[s.route.code]
          service = s.copy!(route, network)
          services << service
          for vj in service.vehicle_journeys
            vehicle_journey = vj.copy!(service, network)
            vehicle_journeys << vehicle_journey
          end
        end
      rescue
        routes.values.each {|x| x.delete() }
        services.each {|x| x.delete() }
        vehicle_journeys.each {|x| x.delete() }
        network.delete
        raise "Cannot create network"
      end
    else
      raise "Cannot create network"
    end
  end

  def route_codes
    routes.map {|x| x.code }
  end

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