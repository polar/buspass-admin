class Masters::Deployments::Networks::NetworkBaseController < Masters::Deployments::DeploymentBaseController
  append_before_filter :set_network


  def api
    @api = {
        :majorVersion => 1,
        :minorVersion => 0,
        "getRoutePath" => route_master_deployment_network_webmap_path(@network, :master_id => @master.id, :deployment_id => @deployment.id),
        "getRouteJourneyIds" => route_journeys_master_deployment_network_webmap_path(@network, :master_id => @master.id, :deployment_id => @deployment.id),
        "getRouteDefinition" => routedef_master_deployment_network_webmap_path(@network, :master_id => @master.id, :deployment_id => @deployment.id),
        "getJourneyLocation" => curloc_master_deployment_network_webmap_path(@network, :master_id => @master.id, :deployment_id => @deployment.id)
    }

    respond_to do |format|
      format.json { render :json => @api }
    end
  end

  private

  def set_network
    @network = Network.find(params[:network_id])
    if @network.nil?
      raise "No Network"
    end
    if @network.deployment != @deployment
      raise "Wrong Network for Deployment"
    end
  end
end