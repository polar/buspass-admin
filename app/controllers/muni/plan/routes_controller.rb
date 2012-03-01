##
# This controller as @network already assigned.
#
class Muni::Plan::RoutesController < Muni::Plan::NetworkController

  def index
    @routes = @network.routes
  end
end