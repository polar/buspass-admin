##
# This class fools the API that Routes are actually timing links
# for the purpose of display.
#
class Masters::Deployments::Simulate::WebmapController < Masters::Deployments::DeploymentBaseController

  def route
    @object ||= Route.find(params[:ref])

    data = getGeoJSON(@object)
    respond_to do |format|
      format.html { render :nothing => true, :status => 404 } # not found
      format.json { render :json => data }
    end
  end

  def journey
    @object ||= VehicleJourney.find(params[:ref])

    data = getGeoJSON(@object)
    respond_to do |format|
      format.html { render :nothing => true, :status => 404 } # not found
      format.json { render :json => data }
    end
  end

  def routedef
    @object = params[:type] == "V" &&
        VehicleJourney.find(params[:ref])
    @object ||= params[:type] == "R" &&
        Route.find(params[:ref])
    # We are only really lax here if we are typing things in.
    @object ||= VehicleJourney.find(params[:ref])
    @object ||= Route.find(params[:ref])

    if @object.is_a? Array
      @object = @object.first
    end
    respond_to do |format|
      format.html { render :nothing => true, :status => 404 } # not found
      format.json { render :json => getDefinitionJSON(@object) }
    end
  end

# We are going return two types, Routes and Active VehicleJourneys.
  def route_journeys
    @routes = @deployment.routes
    rs      = []
    if params[:routes] != nil
      rs = params[:routes].split(',')
    end
    if params[:route]
      rs << params[:route]
    end
    if ! rs.empty?
      @routes.select { |x| rs.include?(x.id) }
    end

    @active_journeys  = ActiveJourney.where(:journey_location_id.ne => nil, :disposition => "simulate", :deployment_id => @deployment.id).all
    @vehicle_journeys = @active_journeys.map { |x| x.vehicle_journey }

    specs = []
    specs += @vehicle_journeys.map { |x| getJourneySpec(x, x.route) }
    specs += @routes.map { |x| getRouteSpec(x) }

    respond_to do |format|
      format.html { render :nothing => true, :status => 404 } # not found
      format.json { render :json => specs }
    end
  end

  # The ref is the journey.id.
  def curloc
    @active_journey = ActiveJourney.where(:journey_location_id.ne => nil,
                                          :disposition   => "simulate",
                                          :vehicle_journey_id  => params[:ref],
                                          :deployment_id => @deployment.id).first

    if @active_journey != nil
      @vehicle_journey = @active_journey.vehicle_journey
      if @active_journey.journey_location != nil
        @journey_location = @active_journey.journey_location
      end
    end

    respond_to do |format|
      format.html { render :nothing => true, :status => 404 } # not found
      format.json {
        if @vehicle_journey == nil
          render :nothing => true, :status => 404 # not found
        else
          render :json => getJourneyLocationJSON(@vehicle_journey, @journey_location)
        end
      }
    end
  end

  private

  def getRouteSpec(route)
    data            = { }
    data["name"]    = route.name.tr(",", "_")
    data["id"]      = "#{route.id}"
    data["type"]    = "R"
    data["version"] = route.version
    return data
  end


  def getJourneySpec(journey, route)
    data         = { }
    data["name"] = journey.display_name.tr(",", "_")
    data["id"]   = "#{journey.id}"
    data["type"] = "V";
    data["routeid"] = "#{route.id}"
    data["version"] = route.version
    return data
  end

  def getDefinitionJSON(route_journey)
    if (route_journey.is_a? Route)
      getRouteDefinitionJSON(route_journey)
    elsif (route_journey.is_a? VehicleJourney)
      getJourneyDefinitionJSON(route_journey)
    else
      nil
    end
  end

  def getRouteDefinitionJSON(route)
    box                = route.theBox # [[nw_lon,nw_lat],[se_lon,se_lat]]
    data               = { }
    data[:_id]         = "#{route.id}"
    data[:_type]       = 'route'
    data[:_name]       = "#{route.display_name}"
    data[:_code]       = "#{route.code}"
    data[:_version]    = "#{route.version}"
    data[:_geoJSONUrl] = route_master_deployment_simulate_webmap_path(@master, @deployment, :ref => route.id, :format => "json")
    data[:_nw_lon]     = "#{box[0][0]}"
    data[:_nw_lat]     = "#{box[0][1]}"
    data[:_se_lon]     = "#{box[1][0]}"
    data[:_se_lat]     = "#{box[1][1]}"
    return data
  end

  def getJourneyDefinitionJSON(journey)
    box                         = journey.journey_pattern.theBox # [[nw_lon,nw_lat],[se_lon,se_lat]]
    data                        = { }
    data[:_id]                  = "#{journey.id}"
    data[:_type]                = 'journey'
    data[:_name]                = "#{journey.display_name}"
    data[:_code]                = "#{journey.service.route.code}"
    data[:_version]             = "#{journey.service.route.version}"
    data[:_geoJSONUrl]          = journey_master_deployment_simulate_webmap_path(@master, @deployment, :ref => journey.id, :format => "json")
    data[:_startOffset]         = "#{journey.start_time}"
    data[:_duration]            = "#{journey.duration}"
    # TODO: TimeZone for Locality.
    data[:_startTime]           = (@master.base_time + journey.start_time.minutes).strftime("%H:%M %P")
    data[:_endTime]             = (@master.base_time + journey.start_time.minutes + journey.duration.minutes).strftime("%H:%M %P")
    data[:_locationRefreshRate] = "10"
    data[:_nw_lon]              = "#{box[0][0]}"
    data[:_nw_lat]              = "#{box[0][1]}"
    data[:_se_lon]              = "#{box[1][0]}"
    data[:_se_lat]              = "#{box[1][1]}"
    return data
  end


# works for VehicleJourney or Route
  def getDefinitionCoords(route)
    if (route.is_a? VehicleJourney)
      patterns = [route.journey_pattern]
    else
      patterns = route.journey_patterns
    end
    # Make the patterns unique.
    cs = []
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
    cs
  end

  def makeGeoJSONGeometry(coords)
    data = {
        "type"        => "LineString",
        "coordinates" => coords
    }
    return data
  end

  def getGeoJSON(route)
    cs         = getDefinitionCoords(route)
    geometries = cs.map { |x| makeGeoJSONGeometry(x) }
    data       = {
        "type"       => "Feature",
        "properties" => { },
        "geometry"   => {
            "type"       => "GeometryCollection",
            "geometries" => geometries
        },
        "crs"        => {
            "type"       => "name",
            "properties" => {
                "name" => "urn:ogc:def:crs:OGC:1.3:CRS84"
            }
        }
    }
    return data
  end

  def getJourneyLocationJSON(journey, journey_location)
    data        = { }
    data[:id]   ="#{journey.id}"
    data[:type] = 'journey'
    data[:name] ="#{journey.display_name}"
    data[:code] ="#{journey.service.route.code}"
    if (journey_location != nil)
      data[:reported]  = journey_location.reported_time.to_i # secs from epoch
      data[:recorded]  = journey_location.recorded_time.to_i # secs from epoch
      data[:lonlat]    = journey_location.coordinates
      data[:timediff]  = journey_location.timediff.to_i      # minutes -early,+late
      data[:direction] = journey_location.direction
      data[:distance]  = journey_location.distance
      data[:on_route]  = journey_location.on_route?
    else
      data[:gone] = true
    end
    return data
  end

end
