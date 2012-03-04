class Muni::Plan::NetworkController < Muni::Plan::ApplicationController

  before_filter :setup_network

  private

  def setup_network
    @network = Network.find(params[:network])
  end

end