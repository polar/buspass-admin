##
# This controller as @network already assigned.
#
class Muni::Networks::RoutesController < Muni::Networks::NetworkBaseController

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
end