##
# This controller as @network already assigned.
#
class Masters::Municipalities::Networks::RoutesController  <
    Masters::Municipalities::Networks::NetworkBaseController

  def index
    @routes = @network.routes.clone
    @routes = @routes.sort { |s1, s2| codeOrd(s1.code, s2.code) }
  end

  def show
    @route = Route.find(params[:id])
    if @route.network != @network
      error  = "not owned by network"
      @route = nil
    end
  end

  def map
    @route = Route.find(params[:id])
    @service = Service.find(params[:service_id])
    if @route.network != @network
      error  = "not owned by network"
      @route = nil
    end
    render :layout => "webmap"
  end

  def api
    @route = Route.find(params[:id])
    @service = Service.find(params[:service_id])
    if @route.network != @network
      raise "wrong network"
    end
    @api = {
        :majorVersion => 1,
        :minorVersion => 0,
        "getRoutePath" => route_master_municipality_network_route_webmap_path(:route_id => @route.id, :service_id => @service.id, :network_id => @network.id, :master_id => @master.id, :municipality_id => @municipality.id),
        "getRouteJourneyIds" => route_journeys_master_municipality_network_route_webmap_path(:route_id => @route.id, :service_id => @service.id, :network_id => @network.id, :master_id => @master.id, :municipality_id => @municipality.id),
        "getRouteDefinition" => routedef_master_municipality_network_route_webmap_path(:id => nil, :route_id => @route.id, :service_id => @service.id, :network_id => @network.id, :master_id => @master.id, :municipality_id => @municipality.id),
        "getJourneyLocation" => curloc_master_municipality_network_route_webmap_path(:route_id => @route.id, :service_id => @service.id, :network_id => @network.id, :master_id => @master.id, :municipality_id => @municipality.id)
    }

    respond_to do |format|
      format.json { render :json => @api }
    end
  end
end