class Masters::Municipalities::Networks::NetworkBaseController < Masters::Municipalities::MunicipalityBaseController
  postpend_before_filter :set_network

  private

  def set_network
    @network = Network.find(params[:network_id])
    if @network.nil?
      raise "No Network"
    end
    if @metwork.municipality != @municipality
      raise "Wrong Network for Deployment"
    end
  end

end