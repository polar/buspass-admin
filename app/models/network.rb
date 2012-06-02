require "carrierwave/orm/mongomapper"

class Network
  include MongoMapper::Document

  key :name,        String
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
  belongs_to  :master

  many :routes, :dependent => :destroy
  many :services, :dependent => :destroy

  # CMS Integration
  one :site, :class_name => "Cms::Site"
  one :page, :class_name => "Cms::Page", :dependent => :destroy

  # This field is where the zipfile gets uploaded. We need to
  # move it to a more permanent place..The Controller will
  # move this to file.
  mount_uploader :upload_file, NetworkFileUploader

  timestamps!

  ensure_index(:name, :unique => false)

  validates_uniqueness_of :name, :scope => [ :master_id, :municipality_id ]

  def self.create_indexes
    self.ensure_index(:name, :unique => true)
  end

  attr_accessible :name, :mode, :description, :municipality

  def copy!(municipality)
    network = Network.new(self.attributes)
    network.municipality = municipality
    network.master = municipality.master
    # May have to change name.
    if network.save(:safe => true)
      routes = {}
      services = []
      vehicle_journeys = []
      begin
        for s in self.services
          if routes[s.route.code] == nil
            routes[s.route.code] = s.route.copy!(network)
          end
          route = routes[s.route.code]
          puts "Copy Service #{s.id} to route #{route.id} and network #{network.id}"
          service = s.copy!(route, network)
          puts "Cone Service #{service.id} "
          services << service
          for vj in s.vehicle_journeys
            vehicle_journey = vj.copy!(service, network)
            vehicle_journeys << vehicle_journey
          end
        end
        network.reload
        network
      rescue  Exception => boom
        routes.values.each {|x| x.delete() }
        services.each {|x| x.delete() }
        vehicle_journeys.each {|x| x.delete() }
        network.delete
        raise "Cannot create network #{boom}"
      end
    else
      raise "Cannot create network"
    end
  end

  def has_errors?
    !processing_errors.empty?
  end

  def owner
    municipality.owner
  end

  def route_codes
    routes.map {|x| x.code }
  end

  def route_count
    routes.count
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