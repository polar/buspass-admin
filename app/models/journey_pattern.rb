#
# A JourneyPattern is an ordered list of JourneyPatternTimingLinks between
# StopPoints. Theoretically, it should be able to have more than one Vechicle
# Journey, but that never really seems to be prudent. This may change in the
# future.
#
class JourneyPattern
  include MongoMapper::EmbeddedDocument
  include LocationBoxing

  embedded_in    :vehicle_journey

  key :name, String

  key :nw_lat, Float
  key :nw_lon, Float
  key :se_lat, Float
  key :se_lon, Float

  key :version_cache, Integer

  many :stop_points, :auto_save => false

  # journey_pattern_timing_links is an ordered list
  many :journey_pattern_timing_links, :autosave => false

  key :coordinates_cache, Array
  #serialize :coordinates_cache

  # Source line from CSV file
  key :csv_file,        String
  key :csv_file_lineno, Integer

  timestamps!

  attr_accessible :name, :csv_file, :csv_file_lineno

  def route
    vehicle_journey.route
  end

  def service
    vehicle_journey.service
  end

  def network
    vehicle_journey.network
  end

  def deployment
    vehicle_journey.deployment
  end

  def master
    vehicle_journey.master
  end

  # We always calculate and save the locator box.

  # We only make the name unique so that we may update them by
  # human sight reading in a CSV file.
  #validates_uniqueness_of :name

  after_validation :assign_lon_lat_locator_fields
  after_validation :assign_version_cache

  def version
    if (version_cache)
      return version_cache
    else
      return get_version
    end
  end

  def get_version
    if updated_at == nil
      return Time.now.to_i
    end
    date = updated_at
    for jptl in journey_pattern_timing_links do
      date = jptl.updated_at? && date < jptl.updated_at ? jptl.updated_at : date
    end
    return date.to_i
  end

  def assign_version_cache
    self.version_cache = get_version
  end

  def journey_path
    "/masters/#{master.id}/deployments/#{deployment.id}/networks/#{network.id}/vehicle_journeys/#{vehicle_journey.id}"
  end

  def jptl_path(jptl)
    "/masters/#{master.id}/deployments/#{deployment.id}/networks/#{network.id}/vehicle_journeys/#{vehicle_journey.id}/journey_pattern_timing_links/#{jptl.id}"
  end

  def has_path_issues?
    journey_pattern_timing_links.reduce(false) {|t,v| v.path_issue != nil || t }
  end
  def has_time_issues?
    journey_pattern_timing_links.reduce(false) {|t,v| v.time_issue != nil || t }
  end

  # We use YourNavigation.org to get the path, and the end points between validate
  # links may not be exactly the same, but should be close enough.
  # Also, due to round off error in the storage of the coordinates,
  # we calculate distance to make sure the last to first coordinates
  # of the respective links are close enough to each other.
  DIST_FUDGE = 100

  def check_consistency
    check_consistency!
  rescue  Exception => boom
    return  boom.to_s
  end

  def check_consistency
    journey_link = "<a href='#{journey_path}'>Journey</a>"
    last_jptl = journey_pattern_timing_links.first
    last_to_location = last_jptl.to.location
    last_coord = last_jptl.view_path_coordinates["LonLat"].last

    #p last_jptl.view_path_coordinates
    for jptl in journey_pattern_timing_links.drop(1) do
      last_jptl_link = "<a href='#{jptl_path(last_jptl)}'>JPTL #{last_jptl.position+1}</a>"
      jptl_link = "<a href='#{jptl_path(jptl)}'>JPTL #{jptl.position+1}</a>"
      location = jptl.from.location
      coord = jptl.view_path_coordinates["LonLat"].first
      if DIST_FUDGE < getGeoDistance(last_to_location.coordinates["LonLat"],location.coordinates["LonLat"])
        str = last_to_location.name != location.name ? " have names that are not equal" : ""
        raise "Inconsistent Locations. End of #{last_jptl_link}: '#{last_to_location.name}' at #{last_to_location.coordinates["LonLat"]} to #{jptl_link}: '#{location.name}' at #{location..coordinates["LonLat"]}#{str}."
      end
      dist = getGeoDistance(last_coord, coord)
      if DIST_FUDGE < dist
        path1str = "#{last_jptl.from.location.coordinates["LonLat"].inspect} - #{last_jptl.view_path_coordinates["LonLat"].inspect} - #{last_jptl.to.location.coordinates["LonLat"].inspect}"
        path2str = "#{jptl.from.location.coordinates["LonLat"].inspect} - #{jptl.view_path_coordinates["LonLat"].inspect} - #{jptl.to.location.coordinates["LonLat"].inspect}"
        raise "Inconsistent Path in #{journey_link}. Distance is #{dist} feet between last point on #{last_jptl_link} at #{last_jptl.to.common_name} #{last_coord.inspect} and first point on #{jptl_link} at #{jptl.from.common_name} #{coord.inspect}."
     end
      last_coord = jptl.view_path_coordinates["LonLat"].last
      last_jptl = jptl
      last_to_location = jptl.to.location
    end
    return nil
  end


  # Names the JPTL with an index into this JourneyPattern.
  def get_journey_pattern_timing_link(position)
    name = "#{self.name} #{position}"
    jptl = journey_pattern_timing_links.find(:name => name)
    jptl ||= JourneyPatternTimingLink.new(
        :name => name,
        :position => position)
    return jptl
  end

  # This function returns if the coordinate lies on the route with the buffer.
  # The buffer is in feet.
  def isOnRoute(coord, buffer)
    journey_pattern_timing_links.reduce(false) {|v,tl| v || tl.isOnRoute(coord, buffer) }
  end

  def view_path_coordinates
    if coordinates_cache
      return { "LonLat" => coordinates_cache }
    else
      if journey_pattern_timing_links.size == 0
        return { "LonLat" => [[0.0,0.0],[0.0,0.0]] }
      else
        return { "LonLat" =>
                     journey_pattern_timing_links.reduce([]) {|v,tl|
                       v.length > 0 && tl.length > 0 && v.last == tl.first ?
                           v + tl.view_path_coordinates["LonLat"].drop(1) :
                           v + tl.view_path_coordinates["LonLat"]}
        }
      end
    end
  end

  def to_kml
    data = view_path_coordinates["LonLat"].map {|lon,lat| "#{lon},#{lat}" }.join(" ")
    html = ""
    html += "<kml xmlns='http://earth.google.com/kml/2.0'>"
    html += "<Document><Folder><Placemark><LineString><coordinates>"
    html += data
    html += "</coordinates></LineString></Placemark></Folder></Document>"
    html += "</kml>"
  end

  def get_geometry
    if journey_pattern_timing_links.size == 0
      return [[0.0,0.0],[0.0,0.0]]
    else
      return journey_pattern_timing_links.reduce([]) {|v,tl|v + tl.view_path_coordinates["LonLat"]}
    end
  end

  # in minutes
  def duration
    journey_pattern_timing_links.reduce(0) {|v,tl| v + tl.time}
  end

  # in feet
  def path_distance
    journey_pattern_timing_links.reduce(0) {|v,tl| v + tl.path_distance}
  end

  #
  # This function returns new estimated location information for
  # time interval in seconds forward of already traveled distance
  # on this journey pattern.
  #
  # Parameters
  #  distance    The already traveled distance
  #  ti_forward  Time in seconds to estimate travel to new location.
  #
  # Returns Hash:
  # Returns Hash
  #  :distance   => Distance from given distance and time at average speed
  #  :coord      => [lon,lat] of point at :distance
  #  :direction  => Direction at pointti_remaining
  #  :speed      => Speed at point
  #
  def location_info_at(distance)
    tls = journey_pattern_timing_links
    current_dist = 0
    ti_dist = 0.minutes
    # We have to find out which JPTL which has to figure the time.
    for tl in tls do
      pathd = tl.path_distance
      if (current_dist + pathd < distance)
        current_dist += pathd
        ti_dist += tl.time.minutes
      else
        ans = tl.location_info_at(distance-current_dist)
        ans[:distance] += current_dist
        ans[:ti_dist] += ti_dist
        return ans
      end
    end
    if (ans == nil)
      raise "Didn't find a suitable answer current_dist = #{current_dist}"
    end
    return ans
  end


  #
  # This function returns new estimated location information for
  # time interval in seconds forward of already traveled distance
  # on this journey pattern.
  #
  # Parameters
  #  distance    The already traveled distance
  #  ti_forward  Time in seconds to estimate travel to new location.
  #
  # Returns Hash:
  # Returns Hash
  #  :distance   => Distance from given distance and time at average speed
  #  :coord      => [lon,lat] of point at :distance
  #  :direction  => Direction at pointti_remaining
  #  :speed      => Speed at point
  #  :ti_remains => time remaining in seconds from ti_forward if
  #                 we reached the end of the path.
  #
  def next_from(distance, ti_forward)
    puts "XXXXXX  next_from(#{distance}, #{ti_forward}"
    ti_remains = ti_forward
    tls = journey_pattern_timing_links
    current_dist = 0
    ti_dist = 0.minutes
    # We have to find out which JPTL which has to figure the time.
    ans = tls[0].location_info_at(0)
    ans[:ti_remains] = ti_remains
    li = 0
    for tl in tls do
      pathd = tl.path_distance
      puts "XXX link #{li} cur_dist=#{current_dist} pathd=#{pathd} ti_remains=#{ti_remains} tl.time=#{tl.time.minutes}"
      if (current_dist + pathd < distance)
        current_dist += pathd
      else
        if (ti_remains > 0)
          # current_dist >= distance && current_dist >= distance - pathd
          # We are almost done. We may hit this twice, because
          # the time left by average speed may take it past
          # the distance of this timing link. If so, we take the
          # ti_remains minus the estimated time it took to get to the end of the
          # timing link. We see where that left over time may get us on the
          # next timing link, if there is one.
          tldist = [pathd, [distance-current_dist,0].max].min
          ans = tl.next_from(tldist, ti_remains)
          current_dist += ans[:distance]
          ti_dist += ans[:ti_dist]
          ans[:distance] = current_dist
          ans[:ti_dist] = ti_dist
          ti_remains = ans[:ti_remains]
        end
      end
      li += 1
    end
    puts "XXXXX Returns #{ans.inspect}"
    return ans
  end

  #
  # This function returns the possible points on
  # this journey pattern. There may be several due to loops.
  #
  # Prerequisite is that this coordinate is on the line.
  #
  # Parameters
  #   coord   The coordinate, which should be on the route.
  #   buffer  The distance buffer from the route in feet.
  #
  # Returns Array of Hashes
  #   :coord  => The point
  #   :distance => The distance to that point.
  #   :direction => The direction at that point.
  #   :ti_dist => The supposed time interval to the point in seconds
  #   :speed => The speed at distance
  #
  def get_possible(coord, buffer)
    tls = journey_pattern_timing_links
    ti_dist = 0.minutes
    distance = 0
    points = []
    for tl in tls do
      # if it is not on this timing link we include
      # it in the distance calulation.
      if (!tl.isOnRoute(coord,buffer))
        distance += tl.path_distance()
        ti_dist += tl.time().minutes
      else
        pts = tl.get_possible(coord,buffer)
        # This function only returns distance and time
        # relative to itself. Add the cumulative distance
        # and time to all points.
        for pt in pts do
          pt[:distance] += distance
          pt[:ti_dist] += ti_dist
        end
        points += pts
      end
    end
    return points
  end

  # T is in miliseconds from 0
  def get_jtpl_for_time(time)
    tls = journey_pattern_timing_links
    begin_time = 0.minutes
    for tl in tls do
      end_time = begin_time + tl.time.minutes
      if begin_time <= t && t <= end_time
        return tl
      end
      begin_time = end_time
    end
    raise "Time is past duration"
  end

  # T is in miliseconds from 0
  def point_on_path(t)
    tls = journey_pattern_timing_links
    begin_time = 0.minutes
    for tl in tls do
      end_time = begin_time + tl.time.minutes
      if begin_time <= t && t <= end_time
        return tl.point_on_path(t-begin_time)
      end
      begin_time = end_time
    end
    raise "Time is past duration"
  end

  # T is in miliseconds from 0
  def direction_on_path(t)
    tls = journey_pattern_timing_links
    begin_time = 0.minutes
    for tl in tls do
      end_time = begin_time + tl.time.minutes
      if begin_time <= t && t <= end_time
        return tl.direction_on_path(t-begin_time)
      end
      begin_time = end_time
    end
    raise "Time is past duration"
  end

  # T is in seconds from 0
  def distance_on_path(t)
    tls = journey_pattern_timing_links
    begin_time = 0.minutes
    distance = 0
    for tl in tls do
      end_time = begin_time + tl.time.minutes
      if begin_time <= t && t <= end_time
        return distance + tl.distance_on_path(t-begin_time)
      end
      distance += tl.path_distance
      begin_time = end_time
    end
    raise "Time is past duration"
  end

  # d is in feet, returns seconds from 0.
  def time_on_path(d)
    tls = journey_pattern_timing_links
    begin_dist = 0
    time = 0
    for tl in tls do
      end_dist = begin_dist + tl.path_distance
      if begin_dist <= d && d <= end_dist
        return time + tl.time_on_path(d-begin_dist)
      end
      time += tl.time.minutes
      begin_dist = end_dist
    end
    raise "Distance is past total distance"
  end

  def starting_direction
    journey_pattern_timing_links.first.starting_direction
  end

  def stop_points
    return [journey_pattern_timing_links.first.from] + journey_pattern_timing_links.map { |jptl| jptl.to }
  end

  def self.find_by_coord(coord)
    # TODO: Faster using a Database query.
    self.all.select {|a| a.locatedBy(coord)}
  end

  def locatedBy(coord)
    inBox(theBox, coord)
  end

  def theBox
    [ [nw_lon, nw_lat], [se_lon, se_lat]]
  end

  # Store the locator box
  def assign_lon_lat_locator_fields
    self.coordinates_cache = get_geometry()

    if (!journey_pattern_timing_links.empty?)
      box = journey_pattern_timing_links.reduce(journey_pattern_timing_links.first.theBox) {|v,jptl| combineBoxes(v,jptl.theBox)}
      self.nw_lon= box[0][0]
      self.nw_lat= box[0][1]
      self.se_lon= box[1][0]
      self.se_lat= box[1][1]
    else
      self.nw_lon= 0
      self.nw_lat= 0
      self.se_lon= 0
      self.se_lat= 0
    end
  end

end
