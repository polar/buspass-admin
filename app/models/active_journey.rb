#
# ActiveJourney are kept around for as long as they need to be for
# being listed on the device. Could also be used for tracking.
#

class ActiveJourney
  include MongoMapper::Document

  key :disposition, String # "active", "test", "simulate"

  belongs_to :vehicle_journey
  belongs_to :service
  belongs_to :route

  belongs_to :journey_location, :dependent => :destroy # may be null

  many :reported_journey_locations, :dependent => :destroy_all

  # Only one of these should be non-nil. This is for look up during
  # Activated Deployment, Test, and Simulation.
  belongs_to :simulate_job
  belongs_to :deployment

  validates_presence_of :vehicle_journey
  validates_presence_of :service
  validates_presence_of :route

  def self.find_by_routes(routes)
    routes = [routes] if routes.is_a? Route
    self.where(:route_id.in => routes.map { |x| x.id }).all
  end

end