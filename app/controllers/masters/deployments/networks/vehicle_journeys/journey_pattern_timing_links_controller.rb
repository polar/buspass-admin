class Masters::Deployments::Networks::VehicleJourneys::JourneyPatternTimingLinksController < Masters::MasterBaseController
  include LocationBoxing

  def getCenter(c1,c2)
    dist = getGeoDistance(c1,c2)
    bearing = getBearing(c1,c2)
    getDestinationPoint(c1,dist/2,bearing)
  end

  def get_context
    get_master_context
    @vehicle_journey = VehicleJourney.find(params[:vehicle_journey_id])
    if @vehicle_journey
      @deployment = @vehicle_journey.deployment
      @network = @vehicle_journey.network
      @journey_pattern_timing_link = @vehicle_journey.journey_pattern_timing_links.find(params[:id])
    else
      @deployment = Deployment.find(params[:deployment_id])
      @network = Network.find(params[:network_id])
    end
    if @master != @deployment.master
      raise "Bad Deployment"
    end
    if @deployment != @network.deployment
      raise "Bad Network"
    end
  end

  def show
    get_context
    authenticate_muni_admin!
    setup_jptls
    render :layout => "masters/map-layout"
  end

  def kml
    get_context
    authenticate_muni_admin!
    render :inline => @journey_pattern_timing_link.to_kml
  end

  def update_timing_links_1
    update_timing_links
  end

  def update_timing_links_2
    update_timing_links
  end

  def update_timing_links
    get_context
    authenticate_muni_admin!

    # This call comes from the "show", so we should have the same environment.
    setup_jptls

    timing_link_ids = params[:timing_links]
    timing_links = timing_link_ids.map do |s|
      vj_id,tl_id = s.split(",").take(2)
      vj = VehicleJourney.where(:master_id => @master.id, :deployment_id => @deployment.id, :network_id => @network.id, :id => vj_id).first;
      if (!vj)
        raise "Not Found"
      end
      tl = vj.journey_pattern.journey_pattern_timing_links.find(tl_id)
      [vj,tl]
    end

    coords = get_coordinates_from_kml(params[:kml])

    if (!coords)
      raise "Illegal KML"
    end

    # We run through them all and check consistency. If one of them fails we do not save any of them.
    timing_links.each do |vj,tl|
      tl.view_path_coordinates = coords
      tl.check_consistency!
      vj.journey_pattern.check_consistency!
    end

    # If we are here, we are okay to save all Vehicle Journeys.
    timing_links.each do |vj,tl|
      vj.path_changed = true
      vj.save
    end

    # Update for table setup.
    @vehicle_journey.reload
    # There is no reload for embedded documents. Just making sure we have the
    # updated one.
    @journey_pattern_timing_link = @vehicle_journey.journey_pattern.journey_pattern_timing_links.find(@journey_pattern_timing_link.id);

    # This call comes from the "show", so we should have the same environment to
    # respond with the table.
    setup_jptls
    if timing_links.length == 0
      @status = "There were no selected timing links to be updated."
    elsif timing_links.length == 1
      @status = "The selected timing link was updated."
    else
      @status = "The #{timing_links.length} selected timing links have been updated."
    end

    @status_type = "success"
  rescue Exception => boom
    @status = "#{boom}"
    @status_type = "error"
  end

  def update_kml
    get_context
    authenticate_muni_admin!
    authorize_muni_admin!(:edit, @network)
    kml = params[:journey_pattern_timing_link][:kml]
    coords = get_coordinates_from_kml(kml)
    if (coords)
      begin
        x = coord_html.inner_html.split(" ")
        x = x.map { |x| x.split(",").take(2).map { |f| f.to_f } }
        @journey_pattern_timing_link.view_path_coordinates = coords
        @journey_pattern_timing_link.google_uri            = kml

        @journey_pattern_timing_link.check_consistency!
        @journey_pattern_timing_link.save
        @vehicle_journey.save
        @status = "JPTL Updated"
      rescue Exception => boom
        @status = "Illegal Path for JPTL Start and End"
      end
    else
      @status = "No KML"
    end
  end

  protected

  def get_coordinates_from_kml(kml)
    if [kml]
      doc = Hpricot(kml)
      if (doc)
        coord_html = doc.at("placemark/linestring/coordinates")
        if coord_html
            x = coord_html.inner_html.split(" ")
            x = x.map { |x| x.split(",").take(2).map { |f| f.to_f } }
            return {:LonLat => x}
        end
      end
    end
  rescue Exception => boom
    return nil
  end

  def setup_jptls

    tosp = @journey_pattern_timing_link.to
    fromsp = @journey_pattern_timing_link.from
    @to = @journey_pattern_timing_link.to.location.coordinates["LonLat"]
    @from = @journey_pattern_timing_link.from.location.coordinates["LonLat"]
    @isConsistent = @journey_pattern_timing_link.check_consistency
    if ! @isConsistent
      flash[:alert] = "The JPTL has a path inconsistent with its endpoints. The current geometry will be connected." +
          " You must hit Update JPTL to save it."

    end

    @kml = @journey_pattern_timing_link.to_kml

    @back_kml = @journey_pattern_timing_link.journey_pattern.to_kml

    @service = @vehicle_journey.service
    @vehicle_journeys = @service.vehicle_journeys
    @journey_links = []
    @vehicle_journeys.each do |vj|
      vj.journey_pattern.journey_pattern_timing_links.each do |jptl|
        if @journey_pattern_timing_link.to.same?(jptl.to) && @journey_pattern_timing_link.from.same?(jptl.from)
          same_path = @journey_pattern_timing_link.view_path_coordinates == jptl.view_path_coordinates
          same_note = vj.note == @vehicle_journey.note
          same_journey = jptl == @journey_pattern_timing_link
          @journey_links << [vj, jptl, same_path, same_note, same_journey]
        end
      end
    end
    @center = getCenter(@from, @to)

    @services = {}
    VehicleJourney.where(:network_id => @network.id, :service_id.ne => @service.id).each do |vj|
       for jptl in vj.journey_pattern_timing_links do
         if jptl.from.same?(fromsp) && jptl.to.same?(tosp)
           same_path = @journey_pattern_timing_link.view_path_coordinates == jptl.view_path_coordinates
           same_note = vj.note == @vehicle_journey.note
           same_route =  vj.service.route == @service.route
           if @services[vj.service] == nil
             @services[vj.service] = [[vj, jptl, same_path, same_note, same_route]]
           else
             @services[vj.service] << [vj, jptl, same_path, same_note, same_route]
           end
         end
       end
    end
  end
end