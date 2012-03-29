##
# This class fools the API that Routes are actually timing links
# for the purpose of display.
#
class Masters::Municipalities::Networks::VehicleJourneys::WebmapController < Masters::Municipalities::Networks::NetworkBaseController

  def route
    @vehicle_journey = VehicleJourney.find(params[:vehicle_journey_id])
    @object = @vehicle_journey.journey_pattern.journey_pattern_timing_links.find(params[:ref])

    data =  getGeoJSON(@object)
    respond_to do |format|
      format.json { render :json => data }
    end
  end

  def journey
    raise "illegal call"
  end

  def routedef
    @vehicle_journey = VehicleJourney.find(params[:vehicle_journey_id])
    @object = @vehicle_journey.journey_pattern.journey_pattern_timing_links.find(params[:ref])

    respond_to do |format|
      format.json { render :json => getDefinitionJSON(@object) }
    end
  end

  # We are going return one types, Each timing link is considered a route.
  def route_journeys
    @vehicle_journey = VehicleJourney.find(params[:vehicle_journey_id])


    specs = []
    specs += @vehicle_journey.journey_pattern.journey_pattern_timing_links.map {|x| getTimingLinkSpec(x)}

    respond_to do |format|
      format.html { render :nothing, :status => 403 } #forbidden
      format.json { render :json => specs }
    end
  end

  def curloc
      raise "Illegal Call"
  end

  # We are going return two types, Routes and VehicleJourneys.
  def all_route_journeys
    railse "Illegal Call"
  end

  private

  def getTimingLinkSpec(timing_link)
    data = {}
    data["name"] = timing_link.name
    data["id"] = timing_link.id.to_s
    data["type"] = "R"
    data["version"] = timing_link.created_at.to_i
    return data
  end


 def getDefinitionJSON(timing_link)
   box = timing_link.theBox # [[nw_lon,nw_lat],[se_lon,se_lat]]
   data = {}
   data[:_id]="#{timing_link.id}"
   data[:_type] = 'route'
   data[:_name]="#{timing_link.from.common_name} - #{timing_link.to.common_name}"
   data[:_code]="#{timing_link.position+1}"
   data[:_version]="#{timing_link.created_at.to_i}"
   data[:_geoJSONUrl]= route_master_municipality_network_vehicle_journey_webmap_path(:ref => timing_link.id, :network_id => @network.id, :master_id => @master.id, :municipality_id => @municipality.id, :vehicle_journey_id => @vehicle_journey.id, :format => "json" )
   data[:_nw_lon]="#{box[0][0]}"
   data[:_nw_lat]="#{box[0][1]}"
   data[:_se_lon]="#{box[1][0]}"
   data[:_se_lat]="#{box[1][1]}"
   return data
 end


 # works for VehicleJourney or Route
 def getDefinitionCoords(timing_link)
     [timing_link.view_path_coordinates["LonLat"] ]
 end

 def makeGeoJSONGeometry(coords)
     data = {
            "type" => "LineString",
            "coordinates" => coords
            }
     return data
 end

  def getGeoJSON(timing_link)
      cs =  getDefinitionCoords(timing_link)
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
