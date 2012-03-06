class Muni::Networks::NetworkBaseController < Muni::ApplicationController
  before_filter :setup_network

  private

  def setup_network
    @network = Network.find(params[:network_id])
    if @network.nil?
      raise "No Network"
    end
  end

end