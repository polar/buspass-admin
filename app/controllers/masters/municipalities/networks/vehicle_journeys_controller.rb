##
# This controller has @network already assigned.
#
class Masters::Municipalities::Networks::VehicleJourneysController <
  Masters::Municipalities::Networks::NetworkBaseController

  def index
    @routes = @network.routes.clone
    @routes = @routes.sort { |s1, s2| codeOrd(s1.code, s2.code) }
  end

  def show
    @vehicle_journey = VehicleJourney.find(params[:id])
    if @vehicle_journey.network != @network
      raise "wrong network"
    end
  end

  def map
    @vehicle_journey = VehicleJourney.find(params[:id])
    if @vehicle_journey.network != @network
      raise "wrong network"
    end
    render :layout => "webmap"
  end

  def api
    @vehicle_journey = VehicleJourney.find(params[:id])
    if @vehicle_journey.network != @network
      raise "wrong network"
    end
    @api = {
        :majorVersion => 1,
        :minorVersion => 0,
        "getRoutePath" => route_master_municipality_network_vehicle_journey_webmap_path(:vehicle_journey_id => @vehicle_journey.id, :network_id => @network.id, :master_id => @master.id, :municipality_id => @municipality.id),
        "getRouteJourneyIds" => route_journeys_master_municipality_network_vehicle_journey_webmap_path(:vehicle_journey_id => @vehicle_journey.id, :network_id => @network.id, :master_id => @master.id, :municipality_id => @municipality.id),
        "getRouteDefinition" => routedef_master_municipality_network_vehicle_journey_webmap_path(:vehicle_journey_id => @vehicle_journey.id, :network_id => @network.id, :master_id => @master.id, :municipality_id => @municipality.id),
        "getJourneyLocation" => curloc_master_municipality_network_vehicle_journey_webmap_path(:vehicle_journey_id => @vehicle_journey.id, :network_id => @network.id, :master_id => @master.id, :municipality_id => @municipality.id)
    }

    respond_to do |format|
      format.json { render :json => @api }
    end
  end

end