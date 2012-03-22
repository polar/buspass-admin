class Masters::Municipalities::Networks::NetworkBaseController < Masters::Municipalities::MunicipalityBaseController
  append_before_filter :set_network

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