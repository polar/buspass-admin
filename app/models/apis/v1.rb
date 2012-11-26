class Apis::V1 < Apis::Base

  ALLOWABLE_CALLS = ["login", "route_journey", "route_journeys", "curloc", "postloc"]

  def initialize(active, api_url_for)
    @api_url_for      = api_url_for
    @active           = active
    @master           = active.master
    @deployment       = active.deployment
    if @active.is_a(Activement)
      @disposition = "active"
    elsif @active.is_a(Testament)
      @disposition = "test"
    end
    @routes           = @deployment.routes
    @vehicle_journeys = @deployment.vehicle_journeys
  end

  def version
    return "1"
  end

  def allowable_calls
    ALLOWABLE_CALLS
  end

  def login(controller)
    text = "<API\n"
    text += "majorVersion='#{version}'\n"
    text += "minorVersion='0'\n"
    text += "user='1'\n"
    text += "getRouteJourneyIds='#{@api_url_for.call("route_journeys")}'\n"
    text += "getRouteDefinition='#{@api_url_for.call("route_journey")}'\n"
    text += "getJourneyLocation='#{@api_url_for.call("curloc")}'\n"
    text += "/>"
    return text
  end

  # We are going return two types, Routes and Active VehicleJourneys.
  def route_journeys(controller)
    params = controller.params
    query_routes = @routes
    rs = []
    if params[:routes] != nil
      rs = params[:routes].split(',')
    end
    if params[:route]
      rs << params[:route]
    end
    if !rs.empty?
      query_routes = query_routes.select { |x| rs.include?(x.id) }
    end

    journey_locations = JourneyLocation.find_by_routes(query_routes)

    text = ""
    text << journey_locations.map { |x| journey_spec(x.vehicle_journey, x.route) }.join("\n")
    if !text.empty?
      text << "\n"
    end
    text << query_routes.map { |x| route_spec(x) }.join("\n")
    return text
  end

  def route_journey(controller)
    params = controller.params
    if params[:type] == "V"
      vehicle_journey = @vehicle_journeys.find { |vj| vj.persistentid == params[:id] }
      if vehicle_journey
        ret = journey_definition(vehicle_journey)
      else
        ret = nil
      end
      return ret
    end

    if params[:type] == "R"
      route = @routes.find { |r| r.persistentid == params[:id] }
      if route
        ret = route_definition(route)
      else
        ret = nil
      end
      return ret
    end
  rescue
    return nil
  end


  def curloc(controller)
    params = controller.params
    vehicle_journey = @vehicle_journeys.find { |vj| vj.persistentid == params[:id] }
    if vehicle_journey.journey_location == nil
      ret = "<NotInService/>"
    else
      lon, lat  = vehicle_journey.journey_location.coordinates
      reported  = vehicle_journey.journey_location.reported_time
      recorded  = vehicle_journey.journey_location.recorded_time
      timediff  = vehicle_journey.journey_location.timediff.to_i
      recorded  = recorded.utc.strftime "%Y-%m-%d %H:%M:%S"
      reported  = reported.utc.strftime "%Y-%m-%d %H:%M:%S"
      direction = vehicle_journey.journey_location.direction
      on_route  = vehicle_journey.journey_location.on_route?
      ret       = "<JP lon='#{lon}' lat='#{lat}' reported_time='#{reported}' recorded_time='#{recorded}' timediff='#{timediff}' direction='#{direction}' onroute='#{on_route}'/>"
    end
    return ret
  rescue
    return nil
  end

  def postloc(controller)
    # TODO: Make sure this is a POST
    params          = controller.params
    vehicle_journey = @vehicle_journeys.find { |vj| vj.persistentid == params[:id] }
    if vehicle_journey.journey_location == nil
      ret = "<NotInService/>"
    else
      loc = vehicle_journey.reported_journey_locations.build(
          {
              :direction     => params[:direction],
              :speed         => params[:speed],
              :reported_time => params[:reported_time],
              :recorded_time => Time.now,
              :disposition   => @disposition,
              :location      =>
                  Location.new(
                      :coordinates =>
                          { "LonLat" => [params[:lon], params[:lat]] }
                  )
          })
      loc.save
      ret = "OK"
    end
    return ret
  end

  private

  def route_spec(route)
    "#{route.name},#{route.persistentid},R,#{route.version}"
  end

  def journey_spec(journey, route)
    "#{journey.display_name},#{journey.persistentid},V,#{route.persistentid},#{route.version}"
  end

  def route_definition(route)
    box = route.theBox # [[nw_lon,nw_lat],[se_lon,se_lat]]

    text = "<Route id='#{route.persistentid}'\n"
    text += "      name='#{route.display_name}'\n"
    text += "      routeCode='#{route.code}'\n"
    text += "      version='#{route.version}'\n"
    text += "      nw_lon='#{box[0][0]}'\n"
    text += "      nw_lat='#{box[0][1]}'\n"
    text += "      se_lon='#{box[1][0]}'\n"
    text += "      se_lat='#{box[1][1]}'>\n"

    patterns = route.journey_patterns
    # Make the patterns unique.
    cs       = []
    for pattern in patterns do
      coords = pattern.view_path_coordinates["LonLat"]
      unique = true
      for c in cs do
        if coords == c
          unique = false
          break
        end
      end
      if unique
        cs << coords
      end
    end

    for coords in cs do
      text += "<JPs>"
      text += coords.map { |lon, lat| "<JP lon='#{lon}' lat='#{lat}' time=''/>\n" }.join
      text += "</JPs>\n"
    end
    text += "</Route>\n"
    return text
  end

  def journey_definition(vehicle_journey)
    box = vehicle_journey.journey_pattern.theBox

    coords = vehicle_journey.journey_pattern.view_path_coordinates["LonLat"]
    text   = "<Route curloc='#{@api_url_for.call(vehicle_journey.persistentid)}'\n"
    text   += "      id='#{vehicle_journey.persistentid}'\n"
    text   += "      routeCode='#{vehicle_journey.service.route.code}'\n"
    text   += "      version='#{vehicle_journey.service.route.version}'\n"
    text   += "      name='#{vehicle_journey.display_name}'\n"
    text   += "      startTime='#{(Time.parse("0:00")+vehicle_journey.start_time.minutes).strftime("%H:%M")}'\n"
    text   += "      endTime='#{(Time.parse("0:00")+vehicle_journey.end_time.minutes).strftime("%H:%M")}'\n"
    text   += "      locationRefreshRate='10'\n"
    text   += "      nw_lon='#{box[0][0]}'\n"
    text   += "      nw_lat='#{box[0][1]}'\n"
    text   += "      se_lon='#{box[1][0]}'\n"
    text   += "      se_lat='#{box[1][1]}'>\n"
    text   += "<JPs>"
    text   += coords.map { |lon, lat| "<JP lon='#{lon}' lat='#{lat}' time=''/>\n" }.join
    text   += "</JPs>\n"
    text   += "</Route>\n"
    return text
  end

end