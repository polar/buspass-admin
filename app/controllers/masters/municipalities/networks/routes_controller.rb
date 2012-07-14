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
    @route = Route.find(params[:route_id])
    @route ||= Route.find(params[:id])
    if @route.network != @network
      error  = "not owned by network"
      @route = nil
    end
    @services = @route.services

  end

  def map
    @route = Route.find(params[:route_id])
    @route ||= Route.find(params[:id])
    @service = Service.find(params[:service_id])
    if @route.network != @network
      error  = "not owned by network"
      @route = nil
    end
  end

  def api
    @route = Route.find(params[:route_id])
    @route ||= Route.find(params[:id])
    @service = Service.find(params[:service_id])
    if @route.network != @network
      raise "wrong network"
    end
    @api = {
        :majorVersion => 1,
        :minorVersion => 0,
        "getRoutePath" => route_master_municipality_network_route_webmap_path(@master, @municipality, @network, @route, :service_id => @service.id),
        "getRouteJourneyIds" => route_journeys_master_municipality_network_route_webmap_path(@master, @municipality, @network, @route, :service_id => @service.id),
        "getRouteDefinition" => routedef_master_municipality_network_route_webmap_path(@master, @municipality, @network, @route, :service_id => @service.id),
        "getJourneyLocation" => curloc_master_municipality_network_route_webmap_path(@master, @municipality, @network, @route, :service_id => @service.id)
    }

    respond_to do |format|
      format.json { render :json => @api }
    end
  end
end