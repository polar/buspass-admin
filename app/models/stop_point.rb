#
# A StopPoint denotes a point on a JourneyPatternTimingLink.
#
class StopPoint
  include MongoMapper::EmbeddedDocument

  key :common_name, String
  one :location, Location

  validates_presence_of   :common_name
  validates_presence_of   :location

end
