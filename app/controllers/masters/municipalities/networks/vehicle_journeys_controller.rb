##
# This controller has @network already assigned.
#
class Masters::Municipalities::Networks::VehicleJourneysController <
  Masters::Municipalities::Networks::NetworkBaseController

  def index
  end

  def show
    @vehicle_journey = VehicleJourney.find(params[:id])
    if @vehicle_journey.network != @network
      raise "wrong network"
    end
  end
end