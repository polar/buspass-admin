#
# ActiveJourney are kept around for as long as they need to be for
# being listed on the device. Could also be used for tracking.
#

class ActiveJourney
  include MongoMapper::Document

  key :disposition, String # "active", "test", "simulate"
  key :persistentid, String

  key :time_start, Time
  key :time_on_route, Integer # minutes
  key :current_distance, Integer # feet.

  belongs_to :vehicle_journey
  belongs_to :service
  belongs_to :route
  belongs_to :master


  belongs_to :journey_location, :dependent => :destroy # may be null

  many :reported_journey_locations, :dependent => :destroy_all

  # Only one of these should be non-nil. This is for look up during
  # Activated Deployment, Test, and Simulation.
  belongs_to :simulate_job
  belongs_to :deployment

  validates_presence_of :vehicle_journey
  validates_presence_of :service
  validates_presence_of :route

  before_validation :assign_persistentid

  def assign_persistentid
    self.persistentid = vehicle_journey.persistentid
  end


  def self.find_by_routes(disp, routes)
    routes = [routes] if routes.is_a? Route
    self.where(:disposition => disp, :route_id.in => routes.map { |x| x.id }).all
  end

  def make_journey_location()
    fields = {}
    fields[:vehicle_journey] = vehicle_journey
    fields[:disposition] = disposition
    fields[:job] = simulate_job
    fields[:route] = route
    fields[:service] = service
    return build_journey_location(fields)
  end
end