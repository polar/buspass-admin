class JourneyLocation
  include MongoMapper::Document

  # Coordinates are { :lat => float, :lon => float }
  # Coordinates are [ lon, lat ]
  key :coordinates, Array
  key :direction, Float
  key :distance, Float
  key :timediff, Integer
  key :reported_time, Time
  key :recorded_time, Time

  key :last_coordinates, Array
  key :last_direction, Float
  key :last_distance, Float
  key :last_timediff, Integer
  key :last_reported_time, Integer


  belongs_to :vehicle_journey
  belongs_to :service
  belongs_to :route

  validates_presence_of :coordinates
  validates_presence_of :vehicle_journey
  validates_presence_of :service
  validates_presence_of :route

  attr_accessible :route, :service, :vehicle_journey,
                  :vehicle_journey_id, :service_id, :route_id,
                  :coordinates, :direction, :timediff, :reported_time, :recorded_time,
                  :last_coordinates, :last_direction, :last_timediff, :last_reported_time

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
