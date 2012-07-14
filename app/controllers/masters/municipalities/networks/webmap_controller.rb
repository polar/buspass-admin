class Masters::Municipalities::Networks::WebmapController < Masters::Municipalities::Networks::NetworkBaseController

  def route
    @object ||= Route.find(params[:ref])

    data =  getRouteGeoJSON(@object)
    respond_to do |format|
      format.json { render :json => data }
    end
  end

  def journey
    raise "Illegal Call"
  end

  def routedef
    @object = Route.find(params[:ref])

    respond_to do |format|
      format.json { render :json => getRouteDefinitionJSON(@object) }
    end
  end

  def route_journeys
    # TODO: searching by :network_id should be sufficient.
    @routes = Route.where(:network_id => @network.id).all
    rs = []
    if params[:routes] != nil
      rs = params[:routes].split(',')
    end
    if params[:route]
      rs << params[:route]
    end
    if !rs.empty?
      @routes.select {|x| rs.include?(x.id)}
    end

    specs = []
    specs += @routes.map {|x| getRouteSpec(x)}

    respond_to do |format|
      format.html { render :nothing => true, :status => 403 } #forbidden
      format.json { render :json => specs }
    end
  end

  def curloc
    raise "Illegal Call"
  end

  private

  def getRouteSpec(route)
    data = {}
    data["name"] = route.name.tr(",","_")
    data["id"] = "#{route.id}"
    data["type"] = "R"
    data["version"] = route.version
    return data
  end

 def getRouteDefinitionJSON(route)
   box = route.theBox # [[nw_lon,nw_lat],[se_lon,se_lat]]
   data = {}
   data[:_id]="#{route.id}"
   data[:_type] = 'route'
   data[:_name]="#{route.display_name}"
   data[:_code]="#{route.code}"
   data[:_version]="#{route.version}"
   data[:_geoJSONUrl]= route_master_municipality_network_webmap_path(@master, @municipality, @network, :ref => route.id, :format => :json)
   data[:_nw_lon]="#{box[0][0]}"
   data[:_nw_lat]="#{box[0][1]}"
   data[:_se_lon]="#{box[1][0]}"
   data[:_se_lat]="#{box[1][1]}"
   return data
 end


 def getRouteDefinitionCoords(route)
     patterns = route.journey_patterns
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
