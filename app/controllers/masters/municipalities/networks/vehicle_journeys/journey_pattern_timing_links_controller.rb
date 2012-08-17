class Masters::Municipalities::Networks::VehicleJourneys::JourneyPatternTimingLinksController < Masters::MasterBaseController
  include LocationBoxing

  def getCenter(c1,c2)
    dist = getGeoDistance(c1,c2)
    bearing = getBearing(c1,c2)
    getDestinationPoint(c1,dist/2,bearing)
  end

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
    @isConsistent = @journey_pattern_timing_link.check_consistency
    if ! @isConsistent
      flash[:alert] = "The JPTL has a path inconsistent with its endpoints. The current geometry will be connected." +
          " You must hit Update JPTL to save it."

    end
    @kml = kml_master_municipality_network_vehicle_journey_journey_pattern_timing_link_path(@master, @municipality, @network, @vehicle_journey, @journey_pattern_timing_link)
    @kml = @journey_pattern_timing_link.to_kml

    @center = getCenter(@from, @to)
    render :layout => "masters/map-layout"
  end

  def kml
    get_context
    authenticate_muni_admin!
    render :inline => @journey_pattern_timing_link.to_kml
  end

  def update_kml
    get_context
    authenticate_muni_admin!
    authorize_muni_admin!(:edit, @network)
    kml = params[:journey_pattern_timing_link][:kml]
    if [kml]
      doc = Hpricot(kml)
      if (doc)
        coord_html = doc.at("placemark/linestring/coordinates")
        if coord_html
          begin
          x = coord_html.inner_html.split(" ")
          x = x.map { |x| x.split(",").take(2).map { |f| f.to_f } }
          @journey_pattern_timing_link.view_path_coordinates = {:LonLat => x}
          @journey_pattern_timing_link.google_uri            = kml

          @journey_pattern_timing_link.check_consistency!
          @journey_pattern_timing_link.save
          @vehicle_journey.save
          @status = "JPTL Updated"
          rescue Exception => boom
            @status = "Illegal Path for JPTL Start and End"
          end

        else
          @status = "Illegal KML"
        end
      else
        @status = "Illegal KML"
      end
    else
      @status = "No KML"
    end
  end
end