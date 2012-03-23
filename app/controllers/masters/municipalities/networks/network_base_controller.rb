class Masters::Municipalities::Networks::NetworkBaseController < Masters::Municipalities::MunicipalityBaseController
  append_before_filter :set_network


  def api
    @api = {
        :majorVersion => 1,
        :minorVersion => 0,
        "getRoutePath" => route_master_municipality_network_webmap_path(@network, :master_id => @master.id, :municipality_id => @municipality.id),
        "getRouteJourneyIds" => route_journeys_master_municipality_network_webmap_path(@network, :master_id => @master.id, :municipality_id => @municipality.id),
        "getRouteDefinition" => routedef_master_municipality_network_webmap_path(@network, :master_id => @master.id, :municipality_id => @municipality.id),
        "getJourneyLocation" => curloc_master_municipality_network_webmap_path(@network, :master_id => @master.id, :municipality_id => @municipality.id)
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
    if @network.municipality != @municipality
      raise "Wrong Network for Deployment"
    end
  end
end