##
# This controller as @network already assigned.
#
class Masters::Deployments::Networks::RoutesController  <
    Masters::Deployments::Networks::NetworkBaseController

  def index
    @routes = @network.routes.clone
    @routes = @routes.sort { |s1, s2| codeOrd(s1.code, s2.code) }
  end

  def show
    @route = Route.find(params[:route_id])
    @route ||= Route.find(params[:id])
    @services = @route.services
  end

  def map
    @route = Route.find(params[:route_id])
    @route ||= Route.find(params[:id])
    @service = Service.find(params[:service_id])
    if @service.nil?
      @services = @route.services
    end
  end

  def api
    @route = Route.find(params[:route_id])
    @route ||= Route.find(params[:id])
    @service = Service.find(params[:service_id])
    if @route.network != @network
      raise "wrong network"
    end
    if @service
      @api = {
          :majorVersion => 1,
          :minorVersion => 0,
          "getRoutePath" => route_master_deployment_network_route_webmap_path(@master, @deployment, @network, @route, :service_id => @service.id),
          "getRouteJourneyIds" => route_journeys_master_deployment_network_route_webmap_path(@master, @deployment, @network, @route, :service_id => @service.id),
          "getRouteDefinition" => routedef_master_deployment_network_route_webmap_path(@master, @deployment, @network, @route, :service_id => @service.id),
          "getJourneyLocation" => curloc_master_deployment_network_route_webmap_path(@master, @deployment, @network, @route, :service_id => @service.id)
      }
    else
      @api = {
          :majorVersion  => 1,
          :minorVersion  => 0,
          "getRoutePath" => route_master_deployment_network_route_webmap_path(@master, @deployment, @network, @route),
          "getRouteJourneyIds" => route_journeys_master_deployment_network_route_webmap_path(@master, @deployment, @network, @route),
          "getRouteDefinition" => routedef_master_deployment_network_route_webmap_path(@master, @deployment, @network, @route),
          "getJourneyLocation" => curloc_master_deployment_network_route_webmap_path(@master, @deployment, @network, @route)
      }
    end

    respond_to do |format|
      format.json { render :json => @api }
    end
  end
end