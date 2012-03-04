
require "csv"
require "open-uri"
require "hpricot"
class ServiceTable

  class Progress < Struct.new(:network)
    def error(s)
      network.errors << s
    end

    def log(s)
      network.processing_log << s
    end

    def initialize(*args)
      super(*args)
      @prog = []
    end

    def progress(level,i,n)
      percent = 0
      @prog[level] = i/n
      while 0 < (level -= 1)
        @prog[level] = 0
      end
      network.processing_progress = @prog.reduce(0) { |t,v| (t + v*10)/10 }
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

  def self.get_vehicle_journey(network, service, journey_pattern, departure_time)
    dtimelit = departure_time.strftime("%H:%M")
    # We use the name of the Service for the Vehicle Journey + the time.
    # Right now we have a 1-1 relationship.
    name = "#{service.name} #{dtimelit}"
    name = "#{service.route.code} #{dtimelit}"
    # This gets the minutes after midnight.
    # TODO: Must work on scheme for minutes before midnight, threshold?
    dtime = (Time.parse(dtimelit)-Time.parse("0:00"))/60
    vehicle_journey =
        VehicleJourney.find_or_initialize_by_name(
            :network_id => network.id,
            :name => name,
            :departure_time => dtime,
            :persistentid => name.hash.abs,  # TODO: We may want to put Network in here.
            :service_id => service.id,
            :journey_pattern_id => journey_pattern.id)
    return vehicle_journey
  end


  def self.generateJPTLs(network, table_file, jptl_dir, progress)
    tab = CSV.read(table_file)
    out = nil

    # Collects Errors for reporting.
    line_count = tab.size
    file_line = 0

    progress.log("Processing #{table_file}. lines #{line_count} to #{jptl_dir}")
    progress.progress(0, 0, line_count)
    progress.commit()

    # We index the journeys, which makes us a persistent
    # name for the JourneyPattern and its JPTLs
    journey_index = 0

    stop_points_changed = false
    locations_changed = false
    direction_changed = false
    start_date_changed = false
    end_date_changed = false

    #
    # Starting reading
    #
    for cols in tab
      file_line += 1
      progress.progress(0, file_line, line_count)

      if cols[0] == "Direction"
        if out != nil
          progress.log("Finished creating JPTLs in #{File.join(jptl_dir,"JPTL-#{service.name}.csv")}")
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
      if stop_points_changed != locations_changed
        progress.error "#{table_file}:#{file_line}:Processing after a 'Stop Points' or 'Locations' line was encountered without a corresponding one. Processing of file stopped."
        raise "cannot continue with this file; inconsistent stop points and locations."
      elsif stop_points_changed
        stop_points_changed = locations_changed = false
      end
      # We can individually change these at any time, but we need them all.
      if !start_date_changed && !end_date_changed && !direction_changed
        progress.error "#{table_file}:#{file_line}:Need to have all 'Start Date', 'End Date', and 'Direction' lines before processing routes. Processing of file stopped."
        raise "cannot continue with this file; needs start date, end date, and direction."
      end
      if stop_point_names == nil || stop_point_locations == nil
        progress.error "#{table_file}:#{file_line}:Need to have 'Stop Points' or 'Locations' lines. Processing of file stopped."
        raise "cannot continue with this file, no stop points or no locations"
      end

      # Otherwise, we start reading JPTLs
      route_number = cols[0]
      day_class = getDesignator(cols[1])
      display_name = cols[2]

      # Route is persistent by the number
      route = Route.find_or_create_by_number(network, route_number)

      # Service is persistent by all of the following arguments.
      service = Service.find_or_create_by_route(network, route.code,
                                                direction, day_class, start_date, end_date)

      if out == nil
        progress.log("Creating JPTLs in #{File.join(jptl_dir,"JPTL-#{service.name}.csv")}")
        out = CSV.open(File.join(jptl_dir,"JPTL-#{service.name}.csv"), "w", :force_quotes => true)
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
            journey_pattern = service.get_journey_pattern(start_time, journey_index, table_file, file_line)
            vehicle_journey = get_vehicle_journey(network, service, journey_pattern, start_time)

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
            jptl.view_path_coordinates = vpc

            # Add and output to "fix it" file.
            journey_pattern.journey_pattern_timing_links << jptl
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
        service.vehicle_journeys << vehicle_journey
        #vehicle_journey.save!
      end
    end
    if out != nil
      progress.log("Finished creating JPTLs in #{File.join(jptl_dir,"JPTL-#{service.name}.csv")}")
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

  def self.createRoute(network, routedir)
    if File.exists? "#{routedir}/Inbound-1.csv"
      self.generateJPTLs(network, "#{routedir}/Inbound-1.csv", "#{routedir}/JPTL-Inbound.csv")
    end
    if File.exists? "#{routedir}/Outbound-1.csv"
      self.generateJPTLs(network, "#{routedir}/Outbound-1.csv", "#{routedir}/JPTL-Outbound.csv")
    end
  end

  def self.fixRoute(network, routedir)
    if File.exists? "#{routedir}/JPTL-Inbound-fixed.csv"
      self.updateJPTLs(network, "#{routedir}/JPTL-Inbound-fixed.csv");
    end
    if File.exists? "#{routedir}/JPTL-Outbound-fixed.csv"
      self.updateJPTLs(network, "#{routedir}/JPTL-Outbound-fixed.csv");
    end
  end

  # For a route that will need to be rebuilt, but is already fixed.
  def self.rebuildRoute(network, routedir)
    self.createRoute(network, routedir)
    self.fixRoute(network, routedir)
  end

  def self.rebuildRoutes(network, routes_dir)
    puts "Rebuilding Routes in #{routes_dir}"
    ::Dir.foreach(routes_dir) do |routedir|
      if (routedir =~ /^Route_.*/)
        path = ::File.expand_path(routedir, routes_dir)
        self.rebuildRoute(network, path)
      end
    end
  end

  def self.dir_structure(dir)
    def self.doit(s, file)
      puts file
      if !(file =~/^\./)
        path = ::File.expand_path(File.join(s[:dir], file))
        if File.directory?(path)
          p Dir.entries(path)
          depth = s[:depth]
          dir = s[:dir]
          s[:depth] += 1
          s[:maxdepth] = [depth+1,s[:maxdepth]].max
          s[:files][ s[:depth] ] ||= []
          s[:dir] = path
          s =  Dir.entries(path).reduce(s) { |s,file| doit(s, file) }
          s[:depth] = depth
          s[:dir] = dir
          return s
        end
        if !(file =~ /^JPTL-/) && (file =~/\.csv$/)
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
    nfiles = s[:files].flatten()
    progress.log("Directory Levels #{s[:depth]+1} consisting of #{nfiles.count} files")
    nfiles.each do |f|
      self.generateJPTLs(network, f, File.dirname(f), progress)
    end
  end

  def self.createRoutes(network, routes_dir)
    puts "Rebuilding Routes in #{routes_dir}"
    ::Dir.foreach(routes_dir) do |routedir|
      if (routedir =~ /^Route_.*/)
        path = ::File.expand_path(routedir, routes_dir)
        self.createRoute(network, path)
      end
    end
  end

  def self.fixRoutes(network, routes_dir)
    puts "Rebuilding Routes in #{routes_dir}"
    ::Dir.foreach(routes_dir) do |routedir|
      if (routedir =~ /^Route_.*/)
        path = ::File.expand_path(routedir, routes_dir)
        self.fixRoute(network, path)
      end
    end
  end

  ##
  ## Typing Convenience Functions
  ##
  def self.routedir
    "#{Rails.root}/db/routes/Network_CENTRO-SU"
  end

  def self.rd(name)
    "#{routedir}/#{name}"
  end

  def self.doR(num)
    self.rebuildRoute(network, rd("Route_#{num}"));
  end

  def self.createR(num)
    self.createRoute(network, rd("Route_#{num}"));
  end

  def self.fixR(num)
    self.fixRoute(network, rd("Route_#{num}"));
  end

  def self.doall
    self.doR 43
    self.doR 340
    self.doR 243
    self.doR 244
    self.doR 44
    self.doR 144
    self.doR 30
    self.doR 343
    self.doR "Sadler"
  end

  def self.cRs
    createRoutes(network, routedir)
  end
end
