##
# This class fools the API that Routes are actually timing links
# for the purpose of display.
#
class Masters::Deployments::WebmapController < Masters::Deployments::DeploymentBaseController

  def route
    @object ||= Network.find(params[:ref])

    data = getNetworkGeoJSON(@object)
    respond_to do |format|
      format.json { render :json => data }
    end
  end

  def journey
    raise "Illegal Call"
  end

  def routedef
    @object = Network.find(params[:ref])
    if @object.is_a? Array
      @object = @object.first
    end
    respond_to do |format|
      format.json { render :json => getNetworkDefinitionJSON(@object) }
    end
  end

# We are going return two types, Routes and Active VehicleJourneys.
  def route_journeys
    @routes = Network.where(:deployment_id => @deployment.id).all
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

    specs = []
    specs += @routes.map { |x| getNetworkSpecAsRoute(x) }

    respond_to do |format|
      format.html { render :nothing => true, :status => 403 } #forbidden
      format.json { render :json => specs }
    end
  end

  def curloc
    raise "illegal call"
  end

  private

  def getNetworkSpecAsRoute(network)
    data            = { }
    data["name"]    = network.name.tr(",", "_")
    data["id"]      = network.id
    data["type"]    = "R"
    data["version"] = network.version
    return data
  end


  def getNetworkDefinitionJSON(network)
    box                = network.theBox # [[nw_lon,nw_lat],[se_lon,se_lat]]
    data               = { }
    data[:_id]         = "#{network.id}"
    data[:_type]       = 'route'
    data[:_name]       = "#{network.name}"
    data[:_code]       = ""
    data[:_version]    = "#{network.version}"
    data[:_geoJSONUrl] = route_master_deployment_webmap_path(@master, @deployment, :ref => network.id, :format => "json")
    data[:_nw_lon]     = "#{box[0][0]}"
    data[:_nw_lat]     = "#{box[0][1]}"
    data[:_se_lon]     = "#{box[1][0]}"
    data[:_se_lat]     = "#{box[1][1]}"
    return data
  end

  def getNetworkDefinitionCoords(network)

    patterns = []

    for route in network.routes do
      patterns += route.journey_patterns
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

  def getNetworkGeoJSON(network)
    cs         = getNetworkDefinitionCoords(network)
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
end
