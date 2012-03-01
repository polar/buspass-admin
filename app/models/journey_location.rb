class JourneyLocation
  include MongoMapper::Document

  # Coordinates are { :lat => float, :lon => float }
  key :coordinates, Hash
  key :last_coordinates, Hash

  belongs_to :vehicle_journey
  belongs_to :service
  belongs_to :route

  validates_presence_of :coordinates
  validates_presence_of :vehicle_journey
  validates_presence_of :service
  validates_presence_of :route

  attr_accessible :route, :service, :vehicle_journey

  before_save  :cache_fields

  def cache_fields
    service = vehicle_journey.service
    route = vehicle_journey.route
  end

  def on_route?
    vehicle_journey.journey_pattern.isOnRoute(coordinates, 60) # 60 feet
  end

  def self.find_by_routes(routes)
    routes = [routes] if !routes.is_a? Array
    JourneyLocation.where(:route_id.in => routes.map { |x| x.id }).all
  end

end
