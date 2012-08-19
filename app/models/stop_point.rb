#
# A StopPoint denotes a point on a JourneyPatternTimingLink.
#
class StopPoint
  include MongoMapper::EmbeddedDocument

  key :common_name, String
  key :location, Location

  attr_accessible :common_name, :location

  def same?(stop_point)
    self.common_name == stop_point.common_name &&
        self.location.same?(stop_point.location)
  end
end
