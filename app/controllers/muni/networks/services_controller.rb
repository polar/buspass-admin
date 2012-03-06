##
# This controller as @network already assigned.
#
class Muni::Networks::ServicesController < Muni::Networks::NetworkBaseController

  def index
    @services = @network.services.clone
    @services = @services.sort {|s1,s2| codeOrd(s1.route.code, s2.route.code)}
  end

  def show
    @service = Service.find(params[:id])
    @journeys = @service.vehicle_journeys
  end
end