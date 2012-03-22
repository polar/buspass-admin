##
# This controller has @network already assigned.
#
class Masters::Municipalities::Networks::VehicleJourneysController <
  Masters::Municipalities::Networks::NetworkBaseController

  def index
    @routes = @network.routes.clone
    @routes = @routes.sort { |s1, s2| codeOrd(s1.code, s2.code) }
  end

  def show
    @vehicle_journey = VehicleJourney.find(params[:id])
    if @vehicle_journey.network != @network
      raise "wrong network"
    end
  end
end