class Apis::V1 < Apis::Base

  ALLOWABLE_CALLS = ["get", "login", "auth", "route_journey", "route_journeys", "curloc", "postloc", "message"]

  def initialize(master, mode, api_url_for)
    @api_url_for = api_url_for
    @mode        = mode
    @master      = master
    @disposition = mode
    @active = master.activement if mode == "active"
    @active = master.testament if mode == "test"
    @deployment = @active.deployment if @active
    if @deployment
      @routes           = @deployment.routes
      @vehicle_journeys = @deployment.vehicle_journeys
    end
  end

  def version
    return @mode == "test" ? "t1" : "1"
  end

  def allowable_calls
    ALLOWABLE_CALLS
  end

  def get(controller)
    text = "<API\n"
    text += "majorVersion='#{version}'\n"
    text += "minorVersion='0'\n"
    text += "mode='#{@mode}'\n"
    text += "name='#{@master.name}'\n"
    text += "auth='#{@api_url_for.call("auth")}'\n"
    text += "login='#{@api_url_for.call("login")}'\n"
    text += "lon='#{@master.longitude}'\n"
    text += "lat='#{@master.latitude}'\n"
    text += "timezone='#{@master.timezone}'\n"
    text += "time='#{Time.now.to_i}'\n"
    text += "timeoffset='#{Time.now.in_time_zone(@master.timezone).utc_offset}'\n"
    text += "datefmt='#{@master.date_format}'\n"
    text += "getRouteJourneyIds='#{@api_url_for.call("route_journeys")}'\n"
    text += "getRouteDefinition='#{@api_url_for.call("route_journey")}'\n"
    text += "getJourneyLocation='#{@api_url_for.call("curloc")}'\n"
    text += "postJourneyLocation='#{@api_url_for.call("postloc")}'\n"
    text += "getMessage='#{@api_url_for.call("message")}'\n"
    text += "/>"
    controller.render :xml => text
  end

  def login(controller)
    controller.redirect_to controller.master_mobile_user_sign_in_url(@master)
  end

  # This is a POST so, redirecting really screws it up.

  def auth(controller)
    #controller.reset_session
    token = controller.params[:access_token]
    user = User.where(:access_token => token).first
    if user
      controller.sign_in(user)

      ## TODO: We should change the token here.

      data = "<login"
      data += " name='#{user.name}'"
      data += " email='#{user.email}'"
      data += " roles='#{user.role_symbols.join(",")}'"
      data += " authToken='#{token}'"
      data += "/>"
      controller.render :xml => data, :status => 200
    else
      controller.render :xml => "<NoWay/>", :status => 404
    end
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

    # Active Journeys may not have a current journey location, but are imminent to be scheduled
    # with in some threshold around their scheduled running time.

    active_journeys = ActiveJourney.find_by_routes(@disposition, query_routes)

    text = ""
    text << active_journeys.map { |x| journey_spec(x.vehicle_journey, x.route) }.join("\n")
    if !text.empty?
      text << "\n"
    end
    text << query_routes.map { |x| route_spec(x) }.join("\n")
    controller.render :text => text
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
      controller.render :text => ret
    end

    if params[:type] == "R"
      route = @routes.find { |r| r.persistentid == params[:id] }
      if route
        ret = route_definition(route)
      else
        ret = nil
      end
      controller.render :text => ret
    end
  rescue
    controller.render :nothing => true, :status => 404
  end


  def curloc(controller)
    params = controller.params

    active_journey = ActiveJourney.where(:journey_location_id.ne => nil,
                                         :disposition => @disposition,
                                         :persistentid => params[:id],
                                         :deployment_id => @deployment.id).first

    if active_journey.nil?
      ret = "<NotInService/>"
    else
      lon, lat  = active_journey.journey_location.coordinates
      reported  = active_journey.journey_location.reported_time
      recorded  = active_journey.journey_location.recorded_time
      timediff  = active_journey.journey_location.timediff.to_i
      recorded  = recorded.utc.strftime "%Y-%m-%d %H:%M:%S"
      reported  = reported.utc.strftime "%Y-%m-%d %H:%M:%S"
      direction = active_journey.journey_location.direction
      on_route  = active_journey.journey_location.on_route?
      ret       = "<JP lon='#{lon}' lat='#{lat}' reported_time='#{reported}' recorded_time='#{recorded}' timediff='#{timediff}' direction='#{direction}' onroute='#{on_route}'/>"
    end
    controller.render :text => ret
  rescue
    controller.render :nothing => true, :status => 404
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
    controller.render :text => ret
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
    text += "type='route'\n"
    text += "name='#{route.display_name}'\n"
    text += "routeCode='#{route.code}'\n"
    text += "sort='#{route.sort}'\n"
    text += "version='#{route.version}'\n"
    text += "nw_lon='#{box[0][0]}'\n"
    text += "nw_lat='#{box[0][1]}'\n"
    text += "se_lon='#{box[1][0]}'\n"
    text += "se_lat='#{box[1][1]}'>\n"

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
    text   += "id='#{vehicle_journey.persistentid}'\n"
    text   += "type='journey'\n"
    text   += "dir='#{vehicle_journey.service.direction}'\n"
    text   += "sort='#{vehicle_journey.service.route.sort}'\n"
    text   += "routeCode='#{vehicle_journey.service.route.code}'\n"
    text   += "version='#{vehicle_journey.service.route.version}'\n"
    text   += "name='#{vehicle_journey.display_name}'\n"
    text   += "startTime='#{(Time.parse("0:00")+vehicle_journey.start_time.minutes).strftime("%H:%M")}'\n"
    text   += "endTime='#{(Time.parse("0:00")+vehicle_journey.end_time.minutes).strftime("%H:%M")}'\n"
    text   += "locationRefreshRate='10'\n"
    text   += "nw_lon='#{box[0][0]}'\n"
    text   += "nw_lat='#{box[0][1]}'\n"
    text   += "se_lon='#{box[1][0]}'\n"
    text   += "se_lat='#{box[1][1]}'>\n"
    text   += "<JPs>"
    text   += coords.map { |lon, lat| "<JP lon='#{lon}' lat='#{lat}' time=''/>\n" }.join
    text   += "</JPs>\n"
    text   += "</Route>\n"
    return text
  end

end