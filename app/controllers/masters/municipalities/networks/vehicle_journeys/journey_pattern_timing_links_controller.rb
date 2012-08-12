class Masters::Municipalities::Networks::VehicleJourneys::JourneyPatternTimingLinksController < Masters::MasterBaseController

  def get_context
    # We should already have master
    @vehicle_journey = VehicleJourney.find(params[:vehicle_journey_id])
    @municipality = @vehicle_journey.municipality
    @network = @vehicle_journey.network
    @journey_pattern_timing_link = @vehicle_journey.journey_pattern_timing_links.find(params[:id])
  end

  def show
    get_context
    authenticate_muni_admin!

    @to = @journey_pattern_timing_link.to.location.coordinates["LonLat"]
    @from = @journey_pattern_timing_link.from.location.coordinates["LonLat"]

    render :layout => "masters/map-layout"
  end
end