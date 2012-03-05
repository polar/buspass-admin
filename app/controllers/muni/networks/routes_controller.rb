##
# This controller as @network already assigned.
#
class Muni::Networks::RoutesController < Muni::ApplicationController

  def index
    @network = Network.find(params[:network_id])
    if @network
      @routes = @network.routes.clone
      @routes = @routes.sort {|s1,s2| codeOrd(s1.code, s2.code)}
    else
      @routes = []
    end

  end
end