class Masters::Municipalities::Networks::Routes::WebmapController < Masters::Municipalities::Networks::NetworkBaseController

  def route
    @route = Route.find(params[:route_id])
    @object ||= VehicleJourney.find(params[:ref])

    data =  getRouteGeoJSON(@object)
    respond_to do |format|
      format.json { render :json => data }
    end
  end

  def journey
    raise "illegal call"
  end

  def routedef
    @vehicle_journey = VehicleJourney.find(params[:ref])

    respond_to do |format|
      format.json { render :json => getJourneyAsRouteDefinitionJSON(@vehicle_journey) }
    end
  end

  def route_journeys
    @route = Route.find(params[:route_id])
    @service = Service.find(params[:service_id])
    @vehicle_journeys = @service.vehicle_journeys

    specs = []
    specs += @vehicle_journeys.map {|x| getJourneySpecAsRoute(x) }

    respond_to do |format|
      format.html { render :nothing, :status => 403 } #forbidden
      format.json { render :json => specs }
    end
  end

  def curloc
    raise "Illegal Call"
  end

  private

  def getJourneySpecAsRoute(journey)
    data = {}
    data["name"] = journey.display_name.tr(",","_")
    data["id"] = journey.id
    data["type"] = "R";
    data["routeid"] = journey.id
    data["version"] = journey.route.version
    return data

  end

   def getJourneyAsRouteDefinitionJSON(journey)
     box = journey.journey_pattern.theBox # [[nw_lon,nw_lat],[se_lon,se_lat]]
     data = {}
     data[:_id]="#{journey.id}"
     data[:_type] = 'route'
     data[:_name]="#{journey.route.display_name} #{(Time.parse("0:00") + journey.start_time.minutes).strftime("%H:%M %P")}"
     data[:_code]="#{journey.route.code}"
     data[:_version]="#{journey.route.version}"
     data[:_geoJSONUrl]= route_master_municipality_network_route_webmap_path(@master, @municipality, @network, journey.route, :ref => journey.id, :format => "json" )
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

end
