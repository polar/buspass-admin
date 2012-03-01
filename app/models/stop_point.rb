#
# A StopPoint denotes a point on a JourneyPatternTimingLink.
#
class StopPoint
  include MongoMapper::EmbeddedDocument

  key :common_name, String
  key :location, Location

  attr_accessible :common_name, :location
end
