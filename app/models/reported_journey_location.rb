class ReportedJourneyLocation
  include MongoMapper::Document

  belongs_to :vehicle_journey

  key :location,      Array
  key :direction,     Float
  key :speed,         Float
  key :reported_time, Time
  key :recorded_time, Time
  key :disposition,    String # "active", "test", or "simulate"

  attr_accessor :variance
  attr_accessor :off_schedule
  attr_accessor :location_info

  def distance
    location_info[:distance]
  end
end
