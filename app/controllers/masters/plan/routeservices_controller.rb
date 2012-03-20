##
# This controller as @network already assigned.
#
class Muni::Plan::RouteservicesController < Muni::Plan::NetworkController
  def index
    @route = Route.find(params[:route])
    @services = @route.services
  end
end