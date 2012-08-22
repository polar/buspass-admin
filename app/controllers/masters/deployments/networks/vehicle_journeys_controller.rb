##
# This controller has @network already assigned.
#
class Masters::Deployments::Networks::VehicleJourneysController <
  Masters::Deployments::Networks::NetworkBaseController

  def index
    @routes = @network.routes.clone
    @routes = @routes.sort { |s1, s2| codeOrd(s1.code, s2.code) }
  end

  def show
    @vehicle_journey = VehicleJourney.find(params[:id])
    if @vehicle_journey.network != @network
      raise "wrong network"
    end
    @service = @vehicle_journey.service
  end

  def map
    @vehicle_journey = VehicleJourney.find(params[:id])
    if @vehicle_journey.network != @network
      raise "wrong network"
    end
    @service = @vehicle_journey.service
  end

  def api
    @vehicle_journey = VehicleJourney.find(params[:id])
    if @vehicle_journey.network != @network
      raise "wrong network"
    end
    @api = {
        :majorVersion => 1,
        :minorVersion => 0,
        "getRoutePath" => route_master_deployment_network_vehicle_journey_webmap_path(@master, @deployment, @network, @vehicle_journey),
        "getRouteJourneyIds" => route_journeys_master_deployment_network_vehicle_journey_webmap_path(@master, @deployment, @network, @vehicle_journey),
        "getRouteDefinition" => routedef_master_deployment_network_vehicle_journey_webmap_path(@master, @deployment, @network, @vehicle_journey),
        "getJourneyLocation" => curloc_master_deployment_network_vehicle_journey_webmap_path(@master, @deployment, @network, @vehicle_journey)
    }

    respond_to do |format|
      format.json { render :json => @api }
    end
  end

end