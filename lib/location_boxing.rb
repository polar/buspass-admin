module LocationBoxing
  def self.getWithinQuery(lon, lat)
    lateq = "(#{lat} BETWEEN nw_lat AND se_lat)"
    if (0 < lon)
      loneq = "(CASE WHEN nw_lon <= se_lon THEN ( nw_lon <= #{lon} AND #{lon} <= se_lon) ELSE nw_lon <= #{lon} END)"
    else
      loneq = "(CASE WHEN nw_lon <= se_lon THEN ( nw_lon <= #{lon} AND #{lon} <= se_lon) ELSE #{lon} <= se_lon END)"
    end
    query = "(" + lateq + " AND " + loneq + ")"
  end

  #
  # Returns the absolute value
  #
  def abs(x)
    x < 0 ? 0-x : x
  end

  #
  # This function returns a box with the NW and SE corner coordinates.
  # We use minimum distance for longitude, i.e. never go around the world
  # the long way. Always the shortest longitudenal distance (< 180 degrees)
  # Note, ambiguity exists if the distance is exactly 180 degrees.
  #   c1        [lon,lat] of the origin
  #   c2        [lon,lat] of the end point
  #
  def getBox(coord1, coord2)
    lon1 = coord1[0]
    lat1 = coord1[1]
    lon2 = coord2[0]
    lat2 = coord2[1]

    nw_lat = lat1 > lat2 ? lat1 : lat2
    se_lat = lat1 < lat2 ? lat1 : lat2

    if lon1 < 0
      if lon2 <= 0
        nw_lon = lon1 < lon2 ? lon1 : lon2
        se_lon = lon1 > lon2 ? lon1 : lon2
      else
        # We need to calculate for the minimum distance
        if abs(lon1 - lon2) < 180
          nw_lon = lon1
          se_lon = lon2
        else
          nw_lon = lon2
          se_lon = lon1
        end
      end
    else
      if lon2 >= 0
        nw_lon = lon1 < lon2 ? lon1 : lon2
        se_lon =-lon1 > lon2 ? lon1 : lon2
      else
        # minimum distance
        if abs(lon1-lon2) < 180
          nw_lon = lon2
          se_lon = lon1
        else
          nw_lon = lon1
          se_lon = lon2
        end
      end
    end
    return [[nw_lon,nw_lat],[se_lon,se_lat]]
  end

  #
  # This function returns the area of the box.
  #    box    [[lon,lat],[lon,lat]] of the box
  #
  def area(box)
    nw_lon = box[0][0]
    nw_lat = box[0][1]
    se_lon = box[1][0]
    se_lat = box[1][1]
    y = abs(nw_lat - se_lat)
    x = abs(nw_lon - se_lon)
    x = x < 180 ? x : 360-x
    return x*y
  end

  #
  # This function returns whether the coordinate is within the box.
  #    box    [[lon,lat],[lon,lat]] of the box
  #    point  [lon,lat]  of the point in question
  #
  def inBox(box, point)
    # Make a box with the point and the SE corner of the box.
    # Make another box with the point and the NE Corner of the box.
    # Combine the new boxes.
    # The point is inside the given box, if the area of the combined boxes is
    # equal (or a little less than due to roundoff error) than the area of the given box.
    box1 = getBox(point,box[1])
    box2 = getBox(box[1],point)
    box3 = combineBoxes( box1, box2 )
    return area(box3) <= area(box)
  end
  def inBox1(box, point)
    # Make a box with the point and the SE corner of the box.
    # Make another box with the point and the NE Corner of the box.
    # Combine the new boxes.
    # The point is inside the given box, if the area of the combined boxes is
    # equal (or a little less than due to roundoff error) than the area of the given box.
    box1 = getBox(point,box[1])
    box2 = getBox(box[1],point)
    box3 = combineBoxes( box1, box2 )
    puts "iB: box = #{box.inspect} point #{point.inspect}"
    puts "iB: box1 = #{box1.inspect} box2 = #{box2.inspect} box3 = #{box3.inspect}"
    puts "iB: area(box) = #{area(box)} area(box1) = #{area(box1)} area(box2) = #{area(box2)} area(box3) = #{area(box3)}"
    return area(box3) <= area(box)
  end

  # This function returns a box that is the combination of boxes.
  # The combination of a box is the NE corner of the box
  # made from the NE of each box argument, and the SE corner of the
  # box made from the SE of each box argument.
  #  box1  [[lon,lat],[lon,lat]]
  #  box2  [[lon,lat],[lon,lat]]
  #
  def combineBoxes( box1, box2 )
    boxA = getBox( box1[0], box2[0])
    boxB = getBox( box1[1], box2[1])
    return getBox(boxA.first, boxB.last)
  end

  # Coordinates are [ [lon,lat], [lon,lat], ...]
  def getBoxForCoordinates(coords)
    coords.drop(1).reduce(getBox(coords.first, coords.first)) { |box,coord| combineBoxes(box,getBox(coord,coord)) }
  end

  #
  # This constant is the latitude degrees for a 1 foot distance
  # on the Earth's surface (estimating perfect sphere).
  #
  LAT_PER_FOOT = 2.738129E-6

  #
  # This constant is the longitude degrees for a 1 foot distance
  # on the Earth's surface (estimating perfect sphere) at the
  # equator. The distance in longitude at a particular latitude
  # is  cos(lat) * LON_PER_FOOT.
  #
  LON_PER_FOOT = 2.738015E-6

  FEET_PER_KM = 3280.84
  #
  # Earth Mean Radius
  #
  EARTH_RADIUS_FEET = 6371.009 * FEET_PER_KM

  def enlargeBox(box,buffer)
    nw_lon = box[0][0]
    nw_lat = box[0][1]
    se_lon = box[1][0]
    se_lat = box[1][1]

    nw_lon = nw_lon - (1/Math.cos(nw_lat) * LON_PER_FOOT) * buffer/2.0
    se_lon = se_lon + (1/Math.cos(se_lat) * LON_PER_FOOT) * buffer/2.0
    nw_lat = nw_lat - buffer/2.0 * LAT_PER_FOOT
    se_lat = se_lat + buffer/2.0 * LAT_PER_FOOT

    if (180 < abs(nw_lon - se_lon))
      raise "Box enlarged to over 180 longitude"
    end
    return [[nw_lon,nw_lat],[se_lon,se_lat]]
  end

  #
  # This function returns the angle (in radians) between
  # the two points.
  #   c1        [lon,lat] of the origin
  #   c2        [lon,lat] of the end point
  #
  def getAngle(c1,c2)
    x = c2[0] - c1[0]
    y = c2[1] - c1[1]
    x = x <= -180 ? x + 360 : x
    x = x >= 180 ? x - 360 : x

    a = Math.atan2(y, x)
  rescue
    p "Error x=#{x}, y=#{y} sq= #{Math.sqrt(x*x+y*y)} rat=#{x / Math.sqrt(x*x+y*y)}"
    raise Error
  end

  def rad(angle)
    Math::PI/180*angle
  end
  def deg(anglerad)
    anglerad * 180 / Math::PI
  end
  def sign(a)
    a == 0 ? 0 : (a < 0 ? -1 : 1)
  end

  #
  # This function delivers the central angle between the two points
  # from the center of the Earth.
  #
  def getCentralAngle(c1,c2)
    # Using the Vincenty Formula
    dlon = rad(c1[0] - c2[0])
    a = Math.cos(rad(c2[1])) * Math.sin(dlon)
    b = Math.cos(rad(c1[1]))*Math.sin(rad(c2[1])) - Math.sin(rad(c1[1])) * Math.cos(rad(c2[1]))*Math.cos(dlon)
    c = Math.sin(rad(c1[1]))*Math.sin(rad(c2[1])) + Math.cos(rad(c1[1])) * Math.cos(rad(c2[1]))*Math.cos(dlon)

    angle = Math.atan2(Math.sqrt(a*a + b*b),c)

    # Using the Haversine Formula

    dLon = rad(c2[0] - c1[0])
    dLat = rad(c2[1] - c1[1])
    lat1 = rad(c1[1])
    lat2 = rad(c2[1])

    a = Math.sin(dLat/2) * Math.sin(dLat/2) +
        Math.sin(dLon/2) * Math.sin(dLon/2) * Math.cos(lat1) * Math.cos(lat2);
    c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));
  end

  #
  # This returns the Geodesic distance on the surface between the two points.
  # It's always positive.
  #
  def getGeoDistance(c1,c2)
    ca = getCentralAngle(c1,c2)
    dist = EARTH_RADIUS_FEET * ca
    return abs(dist)
  end

  def getCenter(c1,c2)
    dist = getGeoDistance(c1,c2)
    bearing = getBearing(c1,c2)
    getDesinationPoint(c1,dist/2,bearing)
  end

  # Returns in Radians from North
  def getBearing(p1, p2)
    dLon = rad(p2[0]-p1[0])
    lat2 = rad(p2[1])
    lat1 = rad(p1[1])
    y = Math.sin(dLon) * Math.cos(lat2)
    x = Math.cos(lat1)*Math.sin(lat2) -
        Math.sin(lat1)*Math.cos(lat2)*Math.cos(dLon)
    brng = Math.atan2(y, x)
  end

  # http://www.movable-type.co.uk/scripts/latlong.html
  def getDestinationPoint(start, d, bearing)
    r = EARTH_RADIUS_FEET
    lon1 = rad(start[0])
    lat1 = rad(start[1])
    lat2 = Math.asin( Math.sin(lat1)*Math.cos(d/r) +
                          Math.cos(lat1)*Math.sin(d/r)*Math.cos(bearing) );
    lon2 = lon1 + Math.atan2(Math.sin(bearing)*Math.sin(d/r)*Math.cos(lat1),
                             Math.cos(d/r)-Math.sin(lat1)*Math.sin(lat2));
    return [deg(lon2),deg(lat2)]
  end
  #
  # This function returns the Angle relative to the equator heading east
  # of the geodesic hypothenuse between the two points. It is directional.
  # Angles greater than PI/2 or less than -PI/2 are heading west from c1 to c2.
  # Otherwise, it's east.
  #
  def getGeoAngle(c1,c2)
    x = c2[0] - c1[0]
    y = c2[1] - c1[1]
    y = y <= -180 ? y+360 : y
    y = y >= 180 ? y-360 : y

    ca = getCentralAngle(c1,c2)
    dist = EARTH_RADIUS_FEET * ca
    ca1 = getCentralAngle(c1,[c2[0],c1[1]])
    dist1 = EARTH_RADIUS_FEET * ca1 * sign(x)
    ca2 = getCentralAngle(c2,[c2[0],c1[1]])
    dist2 = EARTH_RADIUS_FEET * ca2 * sign(y)

    angle = Math.atan2(dist2,dist1)
  end

  def getRealAngle(c1,c2)
    x = c2[0] - c1[0]
    y = c2[1] - c1[1]
    # We select the latitude closest to the equator to find out
    # the logitudinal distance
    lat_angle = abs(c1[1]) < abs(c2[1]) ? c1[1] : c2[1]
    lat_radians = rad(lat_angle)

    dy = y / LAT_PER_FOOT
    dx = x / (1/Math.cos(lat_radians) * LON_PER_FOOT)

    a = Math.atan2(dy,dx)
  rescue
    p "Error x=#{x}, y=#{y} sq= #{Math.sqrt(x*x+y*y)} rat=#{x / Math.sqrt(x*x+y*y)}"
    raise Error
  end

  #
  # This function normalizes a line relative to its
  # origin. It makes sure that we don't wrap
  # over 180 or -180 degrees.
  #   c1        [lon,lat] of the origin
  #   c2        [lon,lat] of the end point
  #
  def normalizeLine(c1,c2)
    x = c2[0] - c1[0]
    y = c2[1] - c1[1]

    # make sure we didn't wrap one way or the other.
    # taking the shortest great circle distance.
    x = x <= -180 ? x + 360 : x
    x = x >= 180 ? x - 360 : x
    return [[0,0],[x,y]]
  end

  #
  # This function normalizes a point relative to a
  # normalizer. It makes sure that we don't wrap
  # over 180 or -180 degrees.
  #   point        [lon,lat] of the point
  #   normalizer   [lon,lat] to be added
  #
  def normalizePoint(point, normalizer)
    x = point[0] + normalizer[0]
    y = point[1] + normalizer[1]
    # make sure we didn't wrap one way or the other.
    # taking the shortest great circle distance.
    x = x <= -180 ? x +360 : x
    x = x >= 180 ? x +360 : x
    return [x,y]
  end

  #
  # Returns the length of the hypothenuse for the line.
  #  c1 [lon,lat] of origin
  #  c2 [lon,lat] of end point
  #
  def distance(c1,c2)
    x = c1[0] - c2[0]
    y = c1[1] - c2[1]
    y = y <= -180 ? y + 360 : y
    y = y >= 180 ? y - 360 : y
    return Math.sqrt(x*x+y*y)
  end

  def getRealDistance(c1,c2)
    y = c1[0] - c2[0]
    x = c1[1] - c2[1]
    # We select the latitude closest to the equator to find out
    # the logitudinal distance
    lat_angle = abs(c1[1]) < abs(c2[1]) ? c1[1] : c2[1]
    x = x <= -180 ? x + 360 : x
    x = x >= 180 ? x - 360 : x
    y_feet = y / (Math.cos(lat_angle)*LON_PER_FOOT)
    x_feet = x / LAT_PER_FOOT
    return Math.sqrt(x_feet*x_feet+y_feet*y_feet)
  end

  #
  # This function creates a location box for a line with a distance buffer in feet
  # that is normalized to have the lower left corner at [-lon(-buffer], lat(-buffer)]
  #   c1  [lon,lat] of origin point
  #   c2  [lon,lat] of end point
  #   buffer feet
  #
  def getNormalizedBoxWidth(c1,c2,buffer)
    line = normalizeLine(c1,c2)
    theta1 = getAngle(line[0],line[1])
    hypot = distance( line[0], line[1] )

    latbuf = buffer * LAT_PER_FOOT
    # Since we normalized lat,lon to the equator projection, we just use this:
    lonbuf = buffer * LON_PER_FOOT

    p1 = [0.0-lonbuf,0.0-latbuf]
    p2 = [hypot*Math.cos(theta1) + lonbuf, hypot*Math.sin(theta1) + latbuf]
    # convert to nw,se box coordinates
    box = getBox(p1, p2)
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
  #
  #   c1  [lon,lat] of origin point
  #   c2  [lon,lat] of end point
  #   buffer in feet
  #   point [lon,lat] of point in question
  #
  def onLine(c1,c2,buffer,c3)

    # we get the difference Geodesic angles
    theta1 = getGeoAngle(c1,c2)
    theta2 = getGeoAngle(c1,c3)
    theta3 = theta2-theta1

    #   buf                         buf
    # (---  c1 ----------------- c2 ---)
    #          *      |
    #   H(c1-c3) *    | H*Sin(theta3)
    #              *  |
    #                c3
    hc1c3 = getGeoDistance(c1,c3)
    hc1c2 = getGeoDistance(c1,c2)
    #
    # if the point is with in a buffer's radius of C1 then it is on the line,
    # Otherwise, its distance from C1 must be less than the distance to C2
    # plus the buffer, and its distance to the C1-C2 line must be less than the buffer.
    # Furthermore this calculation only works if difference in angles is less than PI/2.
    # If the difference in angles is greather than that, then the point is not near
    # the line, unless it was within the buffer radius of C1.
    #
    result = hc1c3 < buffer || abs(theta3) < Math::PI/2 &&
        hc1c3 <= hc1c2 + buffer/2 && abs(Math.sin(theta3) * hc1c3) <= buffer/2

    return result
  end

  def puts_c(c1,c2)
    puts_box([c1,c2])
    puts "#{c2[0]} #{c2[1]}"
  end

  def puts_box(box)
    c1 = box[0]
    c2 = box[1]
    puts "#{c1[0]} #{c1[1]}"
    puts "#{c2[0]} #{c1[1]}"
    puts "#{c2[0]} #{c2[1]}"
    puts "#{c1[0]} #{c2[1]}"
    puts "#{c1[0]} #{c1[1]}"
  end

  def onLine1(c1,c2,buffer,point)

    # we get the difference Geodesic angles
    theta1 = getGeoAngle(c1,c2)
    theta2 = getGeoAngle(c1,c3)
    theta3 = theta2-theta1
    hc1c3 = getGeoDistance(c1,c3)
    hc1c2 = getGeoDistance(c1,c2)
    result = hc1c3 < buffer || abs(theta3) < Math::PI/2 &&
        hc1c3 <= hc1c2 + buffer/2 && abs(Math.sin(theta3) * hc1c3) <= buffer/2


    puts "theta1 = #{theta1} theta2 = #{theta2} theta3 = #{theta3}"
    puts "dist_c2 = #{hc1c3} dist_c3 = #{hc1c3}"
    puts "Result #{result}"

    return result
  end

  #
  # This function returns true if the coordinate is on the given path
  # using a distance buffer in feet along the lines of the path and the
  # buffer around the end points.
  #
  def isOnPath(view_path_coordinates, coord, buffer)
    # We buffer each line on the ends so that an angle turn with the previous
    # or next path line includes the corner.
    # The most radical case being a 90 degree turn.
    #
    #   -----------x
    #   *********  |
    #   ------  *  |
    #        |  *  |
    #        |  *  |
    #
    p1 = view_path_coordinates.first
    for p2 in view_path_coordinates.drop 1 do
      if onLine(p1,p2,buffer,coord)
        return true
      end
      p1 = p2
    end
    return false
  end

  #
  # This function returns the total distance along the path.
  #
  def getPathDistance(view_path_coordinates)
    dist = 0.0
    p1 = view_path_coordinates.first
    for p2 in view_path_coordinates.drop(1) do
      dist += getGeoDistance(p1,p2)
      p1 = p2
    end
    return dist
  end

  #
  # This function returns a point on the path given the average speed
  # at a particular time elapsed from the start. It returns nil if
  # the time is negative or if the time is past the end point at
  # the designated speed.
  #
  # Parameters
  #   view_path_coordinates  [[lon,lat]....]
  #   average_speed  feet/unit_time
  #   time           time_units
  #
  def getPointOnPath(view_path_coordinates, average_speed, time)
    distance = average_speed * time
    ans = getDirectionAndPointOnPath(view_path_coordinates, distance, average_speed)
    return ans[:coord]
  end

  #
  # This function returns a point on the path given the average speed
  # at a particular time elapsed from the start. It returns nil if
  # the time is negative or if the time is past the end point at
  # the designated speed.
  #
  # Parameters
  #   view_path_coordinates  [[lon,lat]....]
  #   average_speed  feet/unit_time
  #   time           time_units
  #
  def getDirectionOnPath(view_path_coordinates, average_speed, time)
    distance = average_speed * time
    ans = getDirectionAndPointOnPath(view_path_coordinates, distance, average_speed)
    return ans[:direction]
  end


  #
  # This function returns the direction and point on the path at
  # a particular distance from the start. It returns the data
  # for the last point on the path  if the given target distance
  # is beyond the length of the path.
  #
  # Parameters
  #   view_path_coordinates  [[lon,lat]....]
  #   target         distance in feet
  # Returns Hash:
  #   :distance => the given distance
  #   :direction => the direction at the point on path
  #   :coord => the [lat,lon] coordinates of the point at target
  #   :ti_dist => the scheduled time to distance.
  #
  def getDirectionAndPointOnPath(view_path_coordinates, target, average_speed)
    dist = 0.0
    vpcs = view_path_coordinates
    #puts "PoP: ***** vps = #{vpcs.inspect}"
    last_point = vpcs.first
    ti_dist = 0
    for p2 in vpcs.drop(1) do
      direction = getBearing(last_point,p2)
      if (dist < target)
        dist2 = dist + getGeoDistance(last_point,p2)
        #puts "PoP: dist = #{dist} target = #{target} dist2 = #{dist2} target-dist = #{target-dist} last_point = #{last_point.inspect} p2= #{p2.inspect}"
        if (target <= dist2)
          lon, lat = getDestinationPoint(last_point,target-dist,direction)
#           ratio = (target-dist)/(dist2-dist)
#           a = getGeoAngle(last_point,p2)
#           lon = last_point[0] + Math.cos(a) * (target-dist) * (1/Math.cos(rad(last_point[1])) * LON_PER_FOOT)
#           lat = last_point[1] + Math.sin(a) * (target-dist) * LAT_PER_FOOT
#           #puts "PoP: a = #{a} dist = #{target-dist} pop = #{[lon,lat].inspect}"
#           # This is just integrity check. It can be eliminated.
          if !onLine(last_point,p2,60,[lon,lat])
            onLine1(last_point,p2,60,[lon,lat])
            raise "Not on Path"
          end
          ti_dist += getGeoDistance(last_point,[lon,lat])/average_speed
          return { :distance => target, :direction => getGeoAngle(last_point,[lon,lat]),
                   :coord => [lon,lat], :ti_dist => ti_dist}
        end
        ti_dist += getGeoDistance(last_point,p2)/average_speed
        dist = dist2
        last_point = p2
      end
    end
    # target is past distance. Return last point.
    return { :distance => dist, :direction => direction, :coord => last_point, :ti_dist => ti_dist }
  end

  def getDirectionOnPathAt(view_path_coordinates, target)
    # It doesn't matter what the speed is for what we are looking for.
    ans = getDirectionOnPath(view_path_coordinates, target, 1)
    return ans[:direction]
  end

  #
  # This function returns the time on the path given the average speed
  # at a particular distance elapsed from the start.
  #
  # Parameters
  #   view_path_coordinates  [[lon,lat]....]
  #   average_speed  feet/miliseconds
  #   distance       feet
  #
  def getTimeOnPath(view_path_coordinates, average_speed, distance)
    target = distance/average_speed # miliseconds
  end

end