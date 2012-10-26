#
# A StopPoint denotes a point on a JourneyPatternTimingLink.
#
class StopPoint
  include MongoMapper::EmbeddedDocument

  key :common_name, String
  key :location, Location

  attr_accessible :common_name, :location

  def same?(stop_point)
    stop_point && self.common_name == stop_point.common_name &&
        self.location.same?(stop_point.location)
  end

  def to_kml(i = nil)
    name = self.common_name.gsub("<", "&lt;").gsub("&", "&amp;").gsub(">", "&gt;")
    if i
      kml = "<Placemark id='sp_#{i}'><name>sp_#{i}:#{name}</name>"
    else
      kml = "<Placemark><name>#{name}</name>"
    end

    kml += "<Point><coordinates>"
    kml += "#{location.coordinates["LonLat"][0]}"
    kml += ","
    kml += "#{location.coordinates["LonLat"][1]}"
    kml += "</coordinates></Point>"

    kml += "</Placemark>"
    kml
  end
end
