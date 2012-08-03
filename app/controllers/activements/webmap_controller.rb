class Activements::WebmapController < ApplicationController

  def route
    get_context

    @object ||=
        Route.where(:persistentid => params[:ref],
                    :master_id => @master.id,
                    :municipality_id => @municipality.id).first
    data =  getRouteGeoJSON(@object)
    respond_to do |format|
      format.json { render :json => data }
    end
  end

  def journey
    get_context

    @object ||=
        VehicleJourney.where(:persistentid => params[:ref],
                             :master_id => @master.id,
                             :municipality_id => @municipality.id).first

    data =  getRouteGeoJSON(@object)
    respond_to do |format|
      format.json { render :json => data }
    end
  end

  def routedef
    get_context

    @object   = params[:type] == "V" &&
                 VehicleJourney.where(:persistentid => params[:ref],
                                      :master_id => @master.id,
                                      :municipality_id => @municipality.id).first
    @object ||= params[:type] == "R" &&
                 Route.where(:persistentid => params[:ref],
                             :master_id => @master.id,
                             :municipality_id => @municipality.id).first

    respond_to do |format|
      format.json { render :json => getDefinitionJSON(@object) }
    end
  end

# We are going return two types, Routes and Active VehicleJourneys.
  def route_journeys
    get_context

    @routes = Route.where(:master_id => @master.id, :municipality_id => @municipality.id).all
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

    @journey_locations = JourneyLocation.where(:municipality_id => @municipality.id).all
    @vehicle_journeys = @journey_locations.map {|x| x.vehicle_journey }

    specs = []
    specs += @vehicle_journeys.map { |x| getJourneySpec(x, @routes[0]) }
    specs += @routes.map { |x| getRouteSpec(x) }

    respond_to do |format|
      format.html { render :nothing, :status => 403 } #forbidden
      format.json { render :json => specs }
    end
  end

  def curloc
    get_context

    # TODO: searching by :municipality_id should be sufficient.
      @vehicle_journey = VehicleJourney.where(:persistentid => params[:ref],
                                              :master_id => @master.id,
                                              :municipality_id => @municipality.id).first

      if @vehicle_journey != nil && @vehicle_journey.journey_location != nil
          @journey_location = @vehicle_journey.journey_location
      end


      respond_to do |format|
          format.html { render :nothing, :status => 403 } #forbidden
          format.json {
            if (@vehicle_journey == nil)
                render :nothing, :status => 505 # not found
            end
            render :json => getJourneyLocationJSON(@vehicle_journey, @journey_location)
            }
      end
  end


  # We are going return two types, Routes and VehicleJourneys.
  def all_route_journeys
    # TODO: searching by :municipality_id should be sufficient.
    @routes = Route.where(:master_id => @master.id, :municipality_id => @municipality.id).all

      # if we have a route or routes parameter, we are only looking for
      # VehicleJourneys.
      rs = []
      if params[:routes] != nil
          rs = params[:routes].split(',').map {|x| x.to_i}
      end
      if params[:route]
          rs << params[:route].to_i
      end
      if !rs.empty?
          @routes = @routes.select {|x| rs.include?(x.persistentid)}
      end

      puts("WE HAVE #{rs.length} Routes Ids " + rs.inspect);
      puts("WE HAVE #{@routes.length} Routes Selected");
      specs = []
      if (!rs.empty?)
        @vehicle_journeys = VehicleJourney.find_by_routes(@routes)
        specs += @vehicle_journeys.map {|x| getJourneySpec(x,x.journey_pattern.route)}
      else
        specs += @routes.map {|x| getRouteSpec(x)}
      end

      puts("WE HAVE #{specs.length} RECORDS TO RETURN!");
      respond_to do |format|
          format.html { render :nothing, :status => 403 } #forbidden
          format.json { render :json => specs }
      end
  end

  private

  def getRouteSpec(route)
    data = {}
    data["name"] = route.name.tr(",","_")
    data["id"] = route.persistentid
    data["type"] = "R"
    data["version"] = route.version
    return data
  end

  def getRouteSpecText(route)
    "#{route.name.tr(",","_")},#{route.persistentid},R,#{route.version}"
  end

  def getJourneySpec(journey, route)
    data = {}
    data["name"] = journey.display_name.tr(",","_")
    data["id"] = journey.persistentid
    data["type"] = "V";
    data["routeid"] = route.persistentid
    data["version"] = route.version
    return data
  end

  def getJourneySpecText(journey, route)
    "#{journey.display_name.tr(",","_")},#{journey.persistentid},V,#{route.persistentid},#{route.version}"
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
   box = route.theBox # [[nw_lon,nw_lat],[se_lon,se_lat]]
   data = {}
   data[:_id]="#{route.persistentid}"
   data[:_type] = 'route'
   data[:_name]="#{route.display_name}"
   data[:_code]="#{route.code}"
   data[:_version]="#{route.version}"
   data[:_geoJSONUrl]= route_activement_webmap_path(:ref => route.persistentid, :format => :json)
   data[:_nw_lon]="#{box[0][0]}"
   data[:_nw_lat]="#{box[0][1]}"
   data[:_se_lon]="#{box[1][0]}"
   data[:_se_lat]="#{box[1][1]}"
   return data
 end

 def getJourneyDefinitionJSON(journey)
   box = journey.journey_pattern.theBox # [[nw_lon,nw_lat],[se_lon,se_lat]]
   data = {}
   data[:_id]="#{journey.persistentid}"
   data[:_type] = 'journey'
   data[:_name]="#{journey.display_name}"
   data[:_code]="#{journey.service.route.code}"
   data[:_version]="#{journey.service.route.version}"
   data[:_geoJSONUrl]= journey_activement_webmap_path(:ref => journey.persistentid, :format => :json)
   data[:_startOffset] = "#{journey.start_time}"
   data[:_duration] ="#{journey.duration}"
   # TODO: TimeZone for Locality.
   data[:_startTime] = (Time.parse("0:00") + journey.start_time.minutes).strftime("%H:%M %P")
   data[:_endTime] = (Time.parse("0:00") + journey.start_time.minutes + journey.duration.minutes).strftime("%H:%M %P")
   data[:_locationRefreshRate] = "10"
   data[:_nw_lon]="#{box[0][0]}"
   data[:_nw_lat]="#{box[0][1]}"
   data[:_se_lon]="#{box[1][0]}"
   data[:_se_lat]="#{box[1][1]}"
   return data
 end


 # works for VehicleJourney or Route
 def getRouteDefinitionCoords(route)
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
            "type" => "LineString",
            "coordinates" => coords
            }
     return data
 end

  def getRouteGeoJSON(route)
      cs =  getRouteDefinitionCoords(route)
      geometries = cs.map {|x| makeGeoJSONGeometry(x)}
      data = {
          "type" => "Feature",
          "properties" => {},
          "geometry" => {
                         "type" => "GeometryCollection",
                         "geometries" => geometries
                        },
          "crs" => {
                    "type"=> "name",
                    "properties" => {
                                     "name" => "urn:ogc:def:crs:OGC:1.3:CRS84"
                                    }
                   }
      }
      return data
  end

  def getJourneyLocationJSON(journey, journey_location)
      data = {}
      data[:id]="#{journey.persistentid}"
      data[:type] = 'journey'
      data[:name]="#{journey.display_name}"
      data[:code]="#{journey.service.route.code}"
      if (journey_location != nil)
        data[:reported]  = journey_location.reported_time.to_i # secs from epoch
        data[:recorded]  = journey_location.recorded_time.to_i # secs from epoch
        data[:lonlat]    = journey_location.coordinates
        data[:timediff]  = journey_location.timediff.to_i # minutes -early,+late
        data[:direction] = journey_location.direction
        data[:distance]  = journey_location.distance
        data[:on_route]  = journey_location.on_route?
      else
        data[:gone] = true
      end
      return data
  end

  def get_context
    @activement = Activement.find(params[:activement_id] || params[:id])
    # TODO: Find by slug
    if @activement == nil
      raise "No Active Deployment Found"
    end
    @master       = @activement.master
    @municipality = @activement.municipality
  end
end
