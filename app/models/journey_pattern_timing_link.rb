class JourneyPatternTimingLink
  include MongoMapper::EmbeddedDocument
  include LocationBoxing

  embedded_in :journey_pattern

  key :name, String
  key :to,   StopPoint
  key :from, StopPoint
  key :time, Integer
  key :google_uri, String

  key :nw_lat, Float
  key :nw_lon, Float
  key :se_lat, Float
  key :se_lon, Float

  key :position, Integer

  key :view_path_coordinates, Hash, :default => { "LonLat" => [[0.0,0.0],[0.0,0.0]] }

  timestamps!

  # We have unique names so that we can readably identify them
  #validates_uniqueness_of :name

  validates_presence_of :time
  validates_presence_of :view_path_coordinates
  validates_presence_of :nw_lat
  validates_presence_of :nw_lon
  validates_presence_of :se_lat
  validates_presence_of :se_lon

  before_validation   :assign_lon_lat_locator_fields

  def init_view_path_coordinates
    if view_path_coordinates == nil
      self.view_path_coordinates = { "LonLat" => [[0.0,0.0],[0.0,0.0]] }
    end
  end

  # We use Google to get the path, and the end points may not be the
  # exact same, but should be close enough. Also, due to round off
  # error in the storage of the coordinates, we calculate distance to
  # make sure the connecting coordinates are close enough to each other.
  DIST_FUDGE = 100

  def check_consistency!
    if ! self.check_consistency
      raise "Inconsistent Path for JPTL\n #{path1str}"
    end
  end

  def check_consistency
    first = view_path_coordinates["LonLat"].first
    last = view_path_coordinates["LonLat"].last
    if DIST_FUDGE < getGeoDistance(from.location.coordinates["LonLat"],first) ||
        DIST_FUDGE < getGeoDistance(to.location.coordinates["LonLat"],last)
      # We have an inconsistency, the points are too far away from each other.
      path1str = "#{from.location.coordinates["LonLat"].inspect} - #{view_path_coordinates["LonLat"].inspect} - #{to.location.coordinates["LonLat"].inspect}"
      return false
    end
    return true
  end

  #
  # Returns the locator bounding box
  #
  def theBox
    [ [nw_lon, nw_lat], [se_lon, se_lat]]
  end

  def getCenter

  end

  #
  # This function returns true if the point coord
  # is on the line [p1, p2]within a particular
  # buffer in feet around the line.
  #   ---------------------------
  #   |           buf           |
  #   |<-buf-><p1-----p2><-buf->|
  #   |           buf           |
  #   ---------------------------

  def isOnRoute(coord, buffer)
    isOnPath(view_path_coordinates["LonLat"], coord, buffer)
  end

  #
  # This asks if the location is in the location box
  #
  def isBoundedBy(coord)
    inBox(getBox([nw_lon,nw_lat],[se_lon,se_lat]),coord)
  end

  def path_distance
    getPathDistance(view_path_coordinates["LonLat"])
  end

  # Feet/second
  def average_speed
    path_distance.to_f/time.minutes
  end

  # t is time in seconds from 0
  def distance_on_path(t)
    # for now, just average
    average_speed * t
  end

  #
  # This function returns the information for the point on the path
  # from the given distance.
  #
  # Parameters
  #   distance   in feet
  #
  # Returns Hash
  #  :distance   => Distance from given distance and time at average speed
  #  :coord      => [lon,lat] of point at :distance
  #  :direction  => Direction at point
  #  :speed      => Speed at point
  #  :ti_dist    => Scheduled Time in seconds to get to distance
  #
  def location_info_at(distance)
    #puts "next_from(#{distance}) : avg = #{average_speed}, dist = #{dist} path_distance = #{path_distance}"
    if (distance > path_distance)
      raise "distance is greater than path distance"
    end
    ans = getDirectionAndPointOnPath(view_path_coordinates["LonLat"], distance, average_speed)
    ans[:speed] = average_speed
    return ans
  end

  #
  # This function returns the information for the next point on the path
  # from the given distance using the given time.
  # If by the time, the calculated distance is past the length of the path
  # then this returns a positive :ti_remains element with the estimated time
  # left over after it reached the end of the path.
  #
  # Parameters
  #   distance   in feet
  #   time       seconds
  #
  # Returns Hash
  #  :distance   => Distance from given distance and time at average speed
  #  :coord      => [lon,lat] of point at :distance
  #  :direction  => Direction at point
  #  :speed      => Speed at point
  #  :ti_dist    => Scheduled Time in seconds to get to distance
  #  :ti_remains => time remaining in seconds from ti_forward if
  #                 we reached the end of the path.
  #
  def next_from(distance, time)
    dist = distance + average_speed * time
    puts "     JPTL:next_from(#{distance},#{time}) : avg = #{average_speed}, dist = #{dist} path_distance = #{path_distance}"
    ans = getDirectionAndPointOnPath(view_path_coordinates["LonLat"], dist, average_speed)
    ans[:speed] = average_speed
    # if the total distance is less than the path distance,
    # then we should have eaten the time remaining. This cuts down
    # on errors such as ti_remains = 5.32907051820075e-15
    if (ans[:distance] < path_distance)
      ans[:ti_remains] = 0.0
    else
      ans[:ti_remains] = time - (ans[:distance]-distance)/average_speed
    end
    puts "     JTP:  returns #{ans.inspect}"
    return ans
  end

  # t is time in miliseconds from 0
  def direction_on_path(t)
    getDirectionOnPath(view_path_coordinates["LonLat"], average_speed, t)
  end

  # d is in feet
  def time_on_path(d)
    getTimeOnPath(view_path_coordinates["LonLat"], average_speed, d)
  end

  # This function returns the estimated LonLat for the location on the
  # path for the time from the start of the link, based upon the average
  # speed.
  # t is time in seconds from 0
  def point_on_path(t)
    coord = getPointOnPath(view_path_coordinates["LonLat"], average_speed, t)
    if !isOnRoute(coord, 60)
      raise "Not on Route"
    end
    coord
  end

  def starting_direction
    vps = view_path_coordinates["LonLat"]
    from_coord = vps[0]
    to_coord = vps[1] # Hopefully there are two!
    return getGeoAngle(from_coord, to_coord)
  end

  # Prerequisite is that this coordinate is on the line.
  def direction(coord, buffer)
    vps = view_path_coordinates["LonLat"]
    vp1 = vps[0]
    vps = vps.drop(1)
    while !vps.empty? do
      vp2 = vps[0]
      vps = vps.drop(1)
      if onLine(vp1, vp2, buffer, coord)
        return getGeoAngle(vp1,vp2)
      end
      vp1 = vp2
    end
    raise "Not on Link"
  end

  #
  # This function returns the possible points on
  # this path. There may be several due to loops.
  #
  # Prerequisite is that this coordinate is on the line.
  #
  # Returns Array of Hashes
  #   :coord  => The point
  #   :distance => The distance to that point.
  #   :direction => The direction at that point.
  #   :ti_dist => The supposed time interval to the point in seconds
  #   :speed => The speed at distance
  #
  def get_possible(coord, buffer)
    vps = view_path_coordinates["LonLat"]
    vp1 = vps[0]
    vps = vps.drop(1)
    path = [vp1]
    points = []
    while (!vps.empty?) do
      vp2 = vps[0]
      vps = vps.drop(1)
      if (onLine(vp1, vp2, buffer, coord))
        dist = getPathDistance(path+[coord])
        ans = getDirectionAndPointOnPath(view_path_coordinates["LonLat"],dist,average_speed)
        points += [ans]
      end
      vp1 = vp2
      path += [vp1]
    end
    return points
  end

  # Store the locator box
  def assign_lon_lat_locator_fields
    box = getBoxForCoordinates( view_path_coordinates["LonLat"] )
    self.nw_lon= box[0][0]
    self.nw_lat= box[0][1]
    self.se_lon= box[1][0]
    self.se_lat= box[1][1]
  end

  def to_kml()
    data = view_path_coordinates["LonLat"].map {|lon,lat| "#{lon},#{lat}" }.join(" ")
    html = ""
    html += "<kml xmlns='http://earth.google.com/kml/2.0'>"
    html += "<Document><Folder><Placemark><LineString><coordinates>"
    html += data
    html += "</coordinates></LineString></Placemark></Folder></Document>"
    html += "</kml>"
  end

end
