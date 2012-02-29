class Network
  include MongoMapper::Document

  key :name,        String
  key :description, String
  key :mode,        String # :planning, :testing, :retired, :active

  belongs_to  :municipality

  many :routes

  timestamps!

  attr_accessible :name, :mode, :municipality, :routes

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
end