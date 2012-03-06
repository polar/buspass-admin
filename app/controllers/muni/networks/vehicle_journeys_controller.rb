class Muni::Networks::VehicleJourneysController < Muni::Networks::NetworkBaseController

  def index
    # TODO: Find a better way?
    redirect_to network_services_path(:muni => @muni.slug, :network_id => @network)
  end

  def show
    @vehicle_journey = VehicleJourney.find(params[:id])
    if @vehicle_journey.network != @network
      raise "wrong network"
    end
  end
end