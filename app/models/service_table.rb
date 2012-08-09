
require "csv"
require "open-uri"
require "hpricot"
class ServiceTable
  include PageUtils

  class Progress < Struct.new(:network)
    def error(s)
      network.processing_errors << s
    end

    def log(s)
      network.processing_log << s
    end

    def initialize(*args)
      super(*args)
      @prog = []
      @totals = [1.0]
    end

    def progress(glevel,j,n)
      level = glevel
      @totals[level] = n.to_f
      @prog[level] = j.to_f
      while 0 <= (level -= 1)
        @prog[level] = 0
        @totals[level] = 1
      end
      i = 0
      value = 0.0
      @totals[@prog.size] = 1.0
      while i < @prog.size
        value = (value + ((@prog[i] / @totals[i]) * (1.0 / @totals[i+1])) * @totals[i+1]) / @totals[i+1]
        i += 1
      end
      p [glevel, j, n]
      p @prog
      p @totals
      p value
      network.processing_progress = value
    end

    def commit
      network.save
    end
  end

  def self.designator
    {
        "W" => "Weekday",
        "D" => "Daily",
        "S" => "Saturday",
        "U" => "Sunday",
        "E" => "Weekend",
        "M" => "Mon-Thurs",
        "F" => "Friday"
    }
  end

  def self.getDesignator(ch)
    x = self.designator[ch]
    if x == nil
      raise "Bad Day Class Designator"
    end
    return x
  end

  def self.constructGoogleMapURI(from,to)
    #locations are stored lon,lat, but google wants them lat,lonlat
    uri = "http://maps.google.com/maps?f=d&source=s_d&saddr=#{from.coordinates["LonLat"].reverse.join(',')}&daddr=#{to.coordinates["LonLat"].reverse.join(',')}"
    return uri
  end

  def self.createStopPoint(stop_name, latlonliteral)
    # TODO: This will be rectified.
    lonlat = eval(latlonliteral).reverse
    location = Location.new( :name => stop_name, :coordinates => { "LonLat" => lonlat } )

    # Not needed for Mongo
    #location.save!
    stop = StopPoint.new( :common_name => stop_name, :location => location )

    # Not needed for Mongo
    #stop.save!
    return stop
  end

  def self.clear
    #Not needed for Mongo.
    #Location.delete_all
    #StopPoint.delete_all
    #JourneyPatternTimingLink.delete_all
    #JourneyPattern.delete_all
    VehicleJourney.delete_all
    Service.delete_all
    Route.delete_all
  end

  # Sometimes we have times out of range. 25:33
  def self.parseTime(timeliteral)
    begin
      if timeliteral.is_a? String
        if (timeliteral.index(':') != nil)
          h,m = timeliteral.split(':').map {|n| n.to_i}
        elsif (timeliteral.index('.') != nil)
          h,m = timeliteral.split('.').map {|n| n.to_i}
        else
          raise "Time Format Error"
        end
      elsif timeliteral.is_a? Float
        h,m = sprintf("%0.2f",timeliteral).split('.').map {|n| n.to_i}
      else
        raise "Time Format Error"
      end
      if (m < 0 || m > 59)
        raise "Time Format Error"
      end
      # works even if hours is negative.  -1.23 means 11:23pm the previous day.
      time = Time.parse("0:00") + h.hours + m.minutes
    rescue
      raise "Invalid Time Error at 111 '#{timeliteral}' h=#{h} m=#{m}"
    end
  end

  def self.create_vehicle_journey(network, service, journey_pattern, departure_time)
    dtimelit = departure_time.strftime("%H:%M")
    # We use the name of the Service for the Vehicle Journey + the time.
    # We add differentiators in case there are two vjs with the same times
    # This could be more efficient, but probably won't happen that much.
    diff = 0
    name = "#{service.name} #{dtimelit}"
    while VehicleJourney.first(:network_id => network.id, :name => name) do
      diff = diff + 1
      name = "#{service.name} #{dtimelit} #{diff}"
    end

    # TODO: Must work on scheme for minutes before midnight, threshold?
    dtime = (Time.parse(dtimelit)-Time.parse("0:00"))/60

    # TODO: PersistentId needs help.
    pid   = (network.name + name).hash.abs
    while VehicleJourney.first(:network_id => network.id, :persistentid => pid) do
      pid += 1
    end
    vehicle_journey = VehicleJourney.new(
        :master          => network.master,
        :municipality    => network.municipality,
        :network         => network,
        :service         => service,
        :name            => name,
        :departure_time  => dtime,
        :persistentid    => pid,
        :journey_pattern => journey_pattern)
    vehicle_journey.save!
    #create_deployment_network_journey_page(network.master.admin_site, network.municipality, network, vehicle_journey)
    #create_deployment_network_journey_map_page(network.master.admin_site, network.municipality, network, vehicle_journey)
    return vehicle_journey
  end


  def self.generateJPTLs(network, dir, file, progress)
    service = nil
    tab = CSV.read(file)
    out = nil

    # Collects Errors for reporting.
    line_count = tab.size
    file_line = 0

    jptl_dir = File.dirname(file)

    table_file = File.join(jptl_dir.sub(/^#{dir}/, "."), File.basename(file))
    out_dirname = File.dirname(table_file)
    jptl_dname = ""

    progress.log("Processing #{table_file} with #{line_count} lines to #{out_dirname}/")
    progress.progress(0, file_line, line_count)
    progress.commit()

    # We index the journeys, which makes us a persistent
    # name for the JourneyPattern and its JPTLs
    journey_index = 0

    stop_points_changed = false
    locations_changed = false
    direction_changed = false
    start_date_changed = false
    end_date_changed = false
    direction = nil
    start_date = nil
    end_date = nil

    #
    # Starting reading
    #
    for cols in tab
      progress.progress(0, file_line, line_count)
      file_line += 1

      if cols[0] == "Direction"
        if out != nil
          progress.log("Finished creating JPTLs in #{jptl_dname} for Direction #{direction}")
          out.close()
          out = nil
        end
        direction = cols[1]
        direction_changed = true
        progress.commit()
        next
      end
      if cols[0] == "Start Date"
        start_date = Date.strptime(cols[1], "%m/%d/%Y").to_time
        start_date_changed = true
        next
      end
      if cols[0] == "End Date"
        end_date = Date.strptime(cols[1], "%m/%d/%Y").to_time
        end_date_changed = true
        next
      end
      if cols[0] == "Route Name"
        route_number = cols[1]
        route = Route.find_or_create_by_number(network, route_number)
        route.display_name = cols[2]
        route.save!
        next
      end
      if cols[0] == "Stop Points"
        # We do not reuse stop points and locations.
        stop_point_names    = cols.drop(3)
        stop_points_changed = true
        next
      end
      if cols[0] == "Locations"
        # We do not reuse stop points and locations.
        stop_point_locations  = cols.drop(3)
        locations_changed = true
        next
      end
      if start_date_changed != end_date_changed
        progress.error "#{table_file}:#{file_line}: Processing after a 'Start Date' or 'End Date' line was encountered without a corresponding one. Processing of file stopped."
        raise "cannot continue with this file; inconsistent stop points and locations."
      elsif start_date_changed
        start_date_changed = end_date_changed = false
      end
      if stop_point_names == nil || stop_point_locations == nil || direction == nil
        progress.error "#{table_file}:#{file_line}: Need to have all 'Stop Points', 'Locations', and 'Direction' lines before processing routes. Processing of file stopped."
        raise "cannot continue with this file; needs start date, end date, and direction."
      else
        # We can individually change these at any time, but we need them all.
        # (sdc || edc || dc) implies ()sdc && edc && dc)
        # ()p implies q) === (!p || q)
        if !(!(stop_points_changed || locations_changed || direction_changed) || (stop_points_changed && locations_changed && direction_changed))
          progress.error "#{table_file}:#{file_line}: Need to change all 'Stop Points', 'Locations', and 'Direction' lines before processing routes. Processing of file stopped."
          raise "cannot continue with this file; needs start date, end date, and direction."
        end
      end
      # We can individually change these at any time, but we need them all.
      if stop_points_changed && locations_changed && direction_changed
        stop_points_changed = false
        locations_changed = false
        direction_changed = false
      end
      if stop_point_names == nil || stop_point_locations == nil || direction == nil
        progress.error "#{table_file}:#{file_line}: Need to have 'Stop Points' and 'Locations' lines. Processing of file stopped."
        raise "cannot continue with this file, no stop points or no locations"
      end
      if start_date == nil || end_date == nil
        progress.error "#{table_file}:#{file_line}: Need to have 'Start Date' and 'End Date' lines. Processing of file stopped."
        raise "cannot continue with this file, no stop points or no locations"
      end
      begin
      # Otherwise, we start reading JPTLs
      route_number = cols[0]
      day_class = getDesignator(cols[1])
      display_name = cols[2]

      #puts "Finding Route and Service"
      # Route is persistent by the number
      route = Route.find_or_create_by_number(network, route_number)
      #create_deployment_network_route_page(network.master.admin_site, network.municipality, network, route)
      #create_deployment_network_route_map_page(network.master.admin_site, network.municipality, network, route)

      # Service is persistent by all of the following arguments.
      service = Service.find_or_create_by_route(route,
                                                direction, day_class, start_date, end_date)
      #create_deployment_network_service_page(network.master.admin_site, network.municipality, network, service)

      #puts "Done Route and Service"
      if out == nil
        jptl_name = "JPTL-#{File.basename(table_file)}"
        jptl_dname = File.join(File.dirname(table_file), jptl_name)
        fname = File.join(dir, File.join(File.dirname(table_file), jptl_name))
        progress.log("Creating JPTLs in #{jptl_dname} for Direction #{direction}")
        out = CSV.open(fname, "w", :force_quotes => true)
        progress.commit()
      end

      # position is the order of the JPTL in the JourneyPattern
      position = 0
      last_stop = nil
      start_time = nil
      last_time = nil

      # Times start on Column D
      times = cols.drop(3)

      progress.log("Service #{service.name}")
      progress.log("#{times.inspect}")
      progress.commit()

      # The last column of the stop_point_names
      # *should be* NOTE and is and end marker
      # and therefore does not contain a time and
      # that is where we stop
      i = 0
      while i < stop_point_names.size-1
        stop_name = stop_point_names[i]
        # We only do something if there is a time in the column
        if times[i] != nil && !times[i].strip.empty?
          if start_time == nil
            # This is the beginning point. The first time found.
            current_time = parseTime(times[i])
            start_time = current_time

            # There is a VehicleJourney and a JourneyPattern
            # for each line associated with this service.
            journey_index += 1

            # Both the JourneyPattern and VehicleJourney are persistent
            # by their constructed names.
            #puts "Getting Journey Pattern and VJ"
            @jv_lookup = Time.now
            journey_pattern = service.get_journey_pattern(start_time, journey_index, table_file, file_line)
            vehicle_journey = create_vehicle_journey(network, service, journey_pattern, start_time)

            #puts "Done Journey Pattern and VJ  #{Time.now - @jv_lookup}"
            # The JourneyPattern is persistent, and so are its JPTLs.
            # So we are replacing any previous JPTLs and regenerating them
            # in case we modified the stop points.
            #journey_pattern.journey_pattern_timing_links.destroy_all
            journey_pattern.journey_pattern_timing_links = []

            # Our starting StopPoint
            latlonliteral = "[#{stop_point_locations[i]}]"
            stop = createStopPoint( stop_name, latlonliteral)

            # Onto the rest
            last_time = start_time
            last_stop = stop
          else
            # If there is a time in this column (i), then we have a link from the
            # last location with a time.
            latlonliteral = "[#{stop_point_locations[i]}]"
            stop = createStopPoint( stop_name, latlonliteral)

            # Create the Link.
            jptl = journey_pattern.get_journey_pattern_timing_link(position)
            jptl.from = last_stop
            jptl.to   = stop

            current_time = parseTime(times[i])
            # time is stored in minutes the link takes to travel
            jptl.time = (current_time-last_time)/60

            # This is the initial path. May have to be modified,
            # which is why the JPTLs have persistent names.
            jptl.google_uri = constructGoogleMapURI(jptl.from.location, jptl.to.location)
            vpc = GoogleUriViewPath.getViewPathCoordinates(jptl.google_uri)
            if ! vpc
              progress.error "Path Error for #{jptl.from.common_name} to #{jptl.to.common_name} for #{jptl.google_uri}"
              if jptl.google_uri.start_with?("http:")
                progress.error "Uri returns #{open("#{jptl.google_uri}&output=kml").to_s}"
              end
            end
            jptl.view_path_coordinates = vpc

            # Add and output to "fix it" file.
            #puts "Adding JPTL #{position}"
            journey_pattern.journey_pattern_timing_links << jptl
            #puts "Done JPTL"
            # Put this out in the file that will get the URIs updated.
            out << [service.name,
                    journey_pattern.name,
                    position,
                    jptl.from.common_name,
                    jptl.to.common_name,
                    jptl.google_uri]

            # Onto the next link, if any.
            position += 1
            last_time = current_time
            last_stop = stop
          end
        else
          # No time, no link
        end
        # Onto the next column
        i += 1
      end
      # Onto the next row
      # This should update the version of the journey_pattern
      # and thereby the version of the route.
      if (journey_pattern != nil )
        journey_pattern.check_consistency!
        #service.journey_patterns << journey_pattern
        vehicle_journey.journey_pattern = journey_pattern
        vehicle_journey.display_name = display_name
        # autosave is false for vehicle_journey
        service.vehicle_journeys << vehicle_journey
        vehicle_journey.save!
      end
      rescue Exception => boom
        progress.error "Error in file #{table_file}: line #{file_line}: #{boom}" + "#{boom.backtrace.select {|s| s.match(/service_table/)}}"
      end
    end
    if out != nil
      progress.log("Finished creating JPTLs in #{jptl_dname} for Direction #{direction}.")
      out.close()
      out = nil
    end

    progress.progress(0, file_line, line_count)
    progress.log("Finished Processing #{table_file}.")
    progress.commit()

  end

  # @param network [Network]
  # @param jptl_file [File]
  # @param progress [Progress]
  def self.updateJPTLs(network, jptl_file, progress)
    tab = CSV.read(jptl_file)
    progress.log("Potentially updating #{tab.count} JPTL links")
    progress.commit()

    for row in tab do
      service = Service.find(:network_id => network.id, :name => row[0])
      if (service != nil)
        vehicle_journey = service.vehicle_journeys.find(:name => row[1])
        if vehicle_journey != nil
          journey_pattern = vehicle_journey.journey_pattern
          if journey_pattern != nil
            jptl= journey_pattern.journey_pattern_timing_links[row[2].to_i]
            if jptl.google_uri != row[5]
              progress.log("Updating #{jptl.name} #{jptl.from.common_name} -> #{jptl.to.common_name}")
              jptl.google_uri = row[5]
              # Could also be a <kml> document from Google Earth
              vpc             = GoogleUriViewPath.getViewPathCoordinates(jptl.google_uri)
              if vpc != nil
                jptl.view_path_coordinates = vpc
              end
              jptl.save!
            end
          else
            progress.log("Cannot find JP for #{row[0]} #{row[1]} #{row[2]}")
          end
          progress.commit()
        end
      end
    end
    return nil
  end

  def self.dir_structure(dir)
    # @param s [Object]
    # @param file [Object]
    def self.doit(s, file)
      if (File.basename(file) =~ /^\./).nil?
        path = ::File.expand_path(File.join(s[:dir], file))
        if File.directory?(path)
          depth = s[:depth]
          dir = s[:dir]
          s[:depth] += 1
          s[:maxdepth] = [depth+1, s[:maxdepth]].max
          s[:files][ s[:depth] ] ||= []
          s[:dir] = path
          s =  Dir.entries(path).reduce(s) { |s,file| doit(s, file) }
          s[:depth] = depth
          s[:dir] = dir
          return s
        end
        if (File.basename(file) =~ /^JPTL-/).nil? && !(File.basename(file) =~/\.csv$/).nil?
          s[:files][ s[:depth] ] << path
          return s
        end
      end
      return s
    end
    doit({:depth => -1, :maxdepth => 0, :files => [], :dir => "/"}, File.expand_path(dir))
  end

  def self.processDirectory(network, dir)
    progress = Progress.new(network)
    progress.log("Processing Directory #{dir}")

    s = self.dir_structure(dir)
    # Ah, we'll just process them flat.
    files = s[:files].flatten()
    nfiles = files.size
    progress.log("Directory Levels #{s[:maxdepth]+1} consisting of #{nfiles} files")
    ifile = 0
    files.each do |f|
      progress.progress(1, ifile, nfiles)
      ifile += 1
      begin
        self.generateJPTLs(network, dir, f, progress)
      rescue Exception => boom
        p boom
        progress.error("#{boom}")
        progress.commit()
      end
    end
  end

  # For a route that will need to be rebuilt, but is already fixed.
  def self.rebuildRoute(network, routedir)
    self.createRoute(network, routedir)
    self.fixRoute(network, routedir)
  end

  def self.rebuildRoutes(network, routes_dir)
    #puts "Rebuilding Routes in #{routes_dir}"
    ::Dir.foreach(routes_dir) do |routedir|
      if (routedir =~ /^Route_.*/)
        path = ::File.expand_path(routedir, routes_dir)
        self.rebuildRoute(network, path)
      end
    end
  end

  def self.createRoutes(network, routes_dir)
    #puts "Rebuilding Routes in #{routes_dir}"
    ::Dir.foreach(routes_dir) do |routedir|
      if (routedir =~ /^Route_.*/)
        path = ::File.expand_path(routedir, routes_dir)
        self.createRoute(network, path)
      end
    end
  end

  def self.fixRoutes(network, routes_dir)
    #puts "Rebuilding Routes in #{routes_dir}"
    ::Dir.foreach(routes_dir) do |routedir|
      if (routedir =~ /^Route_.*/)
        path = ::File.expand_path(routedir, routes_dir)
        self.fixRoute(network, path)
      end
    end
  end
end
