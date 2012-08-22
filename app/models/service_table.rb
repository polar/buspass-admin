
require "csv"
require "open-uri"
require "hpricot"
class ServiceTable
  extend LocationBoxing

  class JobAborted < Exception

  end

  class ProcessingError < Exception

  end

  class NullProgress < Struct.new(:network)
    def initialize(*args)
      super(*args)
    end
    def error(s)
    end
    def log(s)
    end
    def continue!
    end
    def progress(plevel,j,n)
    end
    def commit
    end
  end

  class Progress < NullProgress
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

      if network.processing_job
        # We are running under a Delayed::Job. If it goes away
        # then we must indicate that we are aborting.
        @started_with_job = true
      end
    end

    def continue!
      # if we started by a job, then we don't continue if it goes away. effective abort.
      if @started_with_job && !network.processing_job
        raise JobAborted.new("Job has been aborted.")
      end
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

  def self.day_class
    {
        "Weekday"   => "W",
        "Daily"     => "D",
        "Saturday"  => "S",
        "Sunday"    => "U",
        "Weekend"   => "E",
        "Mon-Thurs" => "M",
        "Friday"    => "F"
    }
  end
  def self.day_class_standard
    {
        "Weekday"   => "MTWRF",
        "Daily"     => "D",
        "Saturday"  => "S",
        "Sunday"    => "U",
        "Weekend"   => "E",
        "Mon-Thurs" => "M",
        "Friday"    => "F"
    }
  end

  def self.day_class_2
    {
        "M" => 1,
        "T" => 2,
        "W" => 4,
        "R" => 8,
        "F" => 16,
        "S" => 32,
        "N" => 64,
        "D" => 1 | 2 | 4 | 8 | 16 | 32 | 64, # MTWRFSN
        "E" => 32 | 64, # SN
        "K" => 1 | 2 | 4 | 8 | 16, # MTWRF
    }
  end

  def self.parseDayClass(dayclass)
     dayclass.split(//).reduce(0) do |t,c|
       x = day_class_2[c]
       if x.nil?
         raise ProcessingError("Bad Day Class #{dayclass}")
       end
       t | x
     end
  end

  def self.getNormalizedDayClass(service)
    cls = ""
    cls << "M" if service.monday
    cls << "T" if service.tuesday
    cls << "W" if service.wednesday
    cls << "R" if service.thursday
    cls << "F" if service.friday
    cls << "S" if service.saturday
    cls << "N" if service.sunday
    return {"MTWRF" => "K", "SN" => "E", "MTWRFSN" => "D"}[cls] || cls
  end

  def self.getDesignator(ch)
    x = self.designator[ch]
    if x == nil
      raise ProcessingError.new("Bad Day Class Designator")
    end
    return x
  end

  def self.fromDayClass(dc)
    x = self.day_class[dc]
    if x == nil
      raise ProcessingError.new("Bad Day Class")
    end
    return x
  end

  def self.constructGoogleMapURI(from,to)
    #locations are stored lon,lat, but google wants them lat,lonlat
    # Google disbanded &output=kml
    # uri = "http://maps.google.com/maps?f=d&source=s_d&saddr=#{from.coordinates["LonLat"].reverse.join(',')}&daddr=#{to.coordinates["LonLat"].reverse.join(',')}"
    uri = "http://www.yournavigation.org/api/1.0/gosmore.php?format=kml&flat=#{from.coordinates["LonLat"][1]}&flon=#{from.coordinates["LonLat"][0]}&tlat=#{to.coordinates["LonLat"][1]}&tlon=#{to.coordinates["LonLat"][0]}7&v=motorcar&fast=1&layer=mapnik&"
    return uri
  end

  def self.createStopPoint(stop_name, latlonliteral)
    lonlat = self.normalizeCoordinates(latlonliteral.split(",").take(2).map {|l| l.to_f}.reverse())

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
          raise ProcessingError.new("Time Format Error")
        end
      elsif timeliteral.is_a? Float
        h,m = sprintf("%0.2f",timeliteral).split('.').map {|n| n.to_i}
      else
        raise ProcessingError.new("Time Format Error")
      end
      if (m < 0 || m > 59)
        raise ProcessingError.new("Time Format Error")
      end
      # works even if hours is negative.  -1.23 means 11:23pm the previous day.
      time = Time.parse("0:00") + h.hours + m.minutes
    rescue
      raise ProcessingError.new("Invalid Time Error at 111 '#{timeliteral}' h=#{h} m=#{m}")
    end
  end

  def self.toTimelit(time, sep = ":")
    timem = (time - Time.parse("0:00"))/60  # could be negative
    # If time is greater than 24 hours, we need to add 24 hours to time.
    dtime = (timem/(60*24)).to_i.abs*24  # hours to add
    hours = (Time.parse("0:00") + timem.minutes).hour + dtime
    mins  = (Time.parse("0:00") + timem.minutes).min
    (timem < 0 ? "~" : "") + ("%02i" % hours) + sep + ("%02i" % mins)
  end

  def self.create_vehicle_journey(network, service, journey_pattern, timelit, departure_time)
    # We use the name of the Service for the Vehicle Journey + the time.
    # We add differentiators in case there are two vjs with the same times
    # This could be more efficient, but probably won't happen that much.
    diff = 0
    name = "#{service.name} #{timelit}"
    while VehicleJourney.first(:network_id => network.id, :name => name) do
      diff = diff + 1
      name = "#{service.name} #{timelit} #{diff}"
    end

    # TODO: PersistentId needs help.
    pid = name.hash.abs
    while VehicleJourney.first(:network_id => network.id, :persistentid => pid) do
      pid += 1
    end
    vehicle_journey = VehicleJourney.new(
        :master          => network.master,
        :deployment    => network.deployment,
        :network         => network,
        :service         => service,
        :name            => name,
        :departure_time  => departure_time,
        :persistentid    => pid,
        :journey_pattern => journey_pattern)
    vehicle_journey.save!(:safe => true)
    #create_deployment_network_journey_page(network.master.admin_site, network.deployment, network, vehicle_journey)
    #create_deployment_network_journey_map_page(network.master.admin_site, network.deployment, network, vehicle_journey)
    return vehicle_journey
  end


  def self.generateJPTLs(cache, network, dir, file, progress)
    service = nil

    jptl_dir = File.dirname(file)

    table_file  = File.join(jptl_dir.sub(/^#{dir}/, "."), File.basename(file))
    out_dirname = File.dirname(table_file)
    jptl_dname  = ""

    progress.log("Processing #{table_file}...")
    tab = nil
    begin
      tab = CSV.read(file, :col_sep => ",")
      progress.log "Processing  #{table_file} with comma separator."
    rescue Exception => boom
      begin
        tab = CSV.read(file, :col_sep => ";")
        progress.log "Processing  #{table_file} with semi-colon separator."
      rescue Exception => boom1
        progress.error("Could not read file #{table_file}. Separators must be comma or semi-colon. Skipping.")
        progress.commit()
      end
    end
    if tab.nil?
      return
    end

    # Collects Errors for reporting.
    line_count = tab.size
    file_line  = 0
    out        = nil

    progress.log("Processing #{table_file} with #{line_count} lines to #{out_dirname}/")
    progress.progress(0, file_line, line_count)
    progress.commit()
    # We index the journeys, which makes us a persistent
    # name for the JourneyPattern and its JPTLs
    journey_index = 0

    direction            = nil
    start_date           = nil
    end_date             = nil
    stop_point_names     = nil
    stop_point_locations = nil

    direction_stage            = nil
    start_date_stage           = nil
    end_date_stage             = nil
    stop_point_names_stage     = nil
    stop_point_locations_stage = nil

    #
    # Starting reading
    #
    for cols in tab
      progress.progress(0, file_line, line_count)
      progress.continue!
      file_line += 1

      if cols[0] == "Direction"
        if out != nil
          progress.log("Finished creating JPTLs in #{jptl_dname} for Direction #{direction}")
          out.close()
          out = nil
        end
        direction_stage   = cols[1]
        direction = nil
        progress.commit()
        next
      end
      if cols[0] == "Start Date"
        start_date_stage = Date.strptime(cols[1], "%m/%d/%Y").to_time
        start_date = nil
        next
      end
      if cols[0] == "End Date"
        end_date_stage = Date.strptime(cols[1], "%m/%d/%Y").to_time
        end_date = nil
        next
      end
      if cols[0] == "Route Name"
        route_code         = cols[1]
        route              = Route.definitely_get_route(network, route_code)
        route.display_name = cols[2]
        route.sort         = cols[3].to_i
        route.save!
        next
      end
      if cols[0] == "Stop Points"
        stop_point_names_stage    = cols.drop(3)
        stop_point_names = nil
        next
      end
      if cols[0] == "Locations"
        stop_point_locations_stage = cols.drop(3)
        stop_point_locations = nil
        next
      end
      # We should have a VehicleJourney/Service entry here. Check that we got everything we need.
      # StopPoints, Locations, Direction, StartDate, EndDate,
      if start_date_stage && end_date_stage
        start_date = start_date_stage
        end_date = end_date_stage
        start_date_stage = nil
        end_date_stage = nil

        if (start_date > end_date)
          progress.error "#{table_file}:#{file_line}: Start Date must be after End Date"
          raise "cannot continue with this file -- bad date configuration."
        end
      end
      # We can individually change these at any time, but we need them all.
      if  stop_point_names_stage  && stop_point_locations_stage && direction_stage
        stop_point_names     = stop_point_names_stage
        stop_point_locations = stop_point_locations_stage
        direction            = direction_stage
        stop_point_names_stage     = nil
        stop_point_locations_stage = nil
        direction_stage            = nil
        if stop_point_names.length < 3 # includes "NOTE"
          progress.error "#{table_file}:#{file_line}: You need to have at least 2 stop points for a journey followed by NOTE."
          raise ProcessingError.new("cannot continue with this file -- needs at least 2 stop points.")
        end
        if stop_point_locations.length < stop_point_names.length-1
          progress.error "#{table_file}:#{file_line}: You need to have at least a location for each stop point."
          raise ProcessingError.new("cannot continue with this file -- need a location under every stop point.")
        end
        n = 0
        while n < stop_point_names.length && stop_point_names[n] && stop_point_names[n].downcase != "note" do
          if (stop_point_locations[n].blank?)
            progress.error "#{table_file}:#{file_line}: Stop points must have a location under them."
            raise ProcessingError.new("cannot continue with this file -- stop points missing enough locations.")
          end
          n += 1
        end
        if n == stop_point_names.length
          progress.error "#{table_file}:#{file_line}: Stop points must end with 'NOTE'"
          raise ProcessingError.new("cannot continue with this file -- stop points must end with 'NOTE'.")
        end
        if ! stop_point_names[n]
          progress.error "#{table_file}:#{file_line}: Stop point #{n+1} must have a name."
          raise ProcessingError.new("cannot continue with this file -- stop point missing name.")
        end
        if  stop_point_names[n].downcase != "note"
          progress.error "#{table_file}:#{file_line}: Stop points must end with 'NOTE'"
          raise ProcessingError.new("cannot continue with this file -- stop points must end with 'NOTE'.")
        end
      end
      if stop_point_names == nil || stop_point_locations == nil || direction == nil
        progress.error "#{table_file}:#{file_line}: Need to have the 'Stop Points', 'Locations', and 'Direction' lines before processing routes. Processing of file stopped."
        raise ProcessingError.new("cannot continue with this file -- needs stop points, locations, and direction.")
      end
      if start_date == nil || end_date == nil
        progress.error "#{table_file}:#{file_line}: Need to have 'Start Date' and 'End Date' lines. Processing of file stopped."
        raise ProcessingError.new("cannot continue with this file -- needs start date and end date.")
      end
      begin
        # If we catch a ProcessingError in here, we just ignore that VehicleJourney.

        # Start reading a VehicleJourney
        route_code   = cols[0]
        day_class    = getDesignator(cols[1])
        display_name = cols[2]

        #puts "Finding Route and Service"
        # Route is persistent by the number
        route        = Route.definitely_get_route(network, route_code)

        #create_deployment_network_route_page(network.master.admin_site, network.deployment, network, route)
        #create_deployment_network_route_map_page(network.master.admin_site, network.deployment, network, route)

        if route.nil?
          raise "WTF 1 Route is nil #{route_code}"
        end

        # Service is persistent by all of the following arguments.
        # It always has the same stop points
        service = Service.find_or_create_by_route(route,
                                                  direction, day_class, start_date, end_date)

        if service.route.nil?
          progress.error "#{table_file}:#{file_line}: Service is nil #{service.name} Route #{route.name}"
          progress.commit();
          raise "WTF 2. Service. route is  nil #{service.name}"
        end

        if service.stop_points.empty?
          service.csv_stop_point_names = stop_point_names
          service.csv_locations        = stop_point_locations
          service.csv_lineno           = file_line
          service.csv_filename         = table_file
          service.stop_points          = []
          i = 0
          while i < stop_point_names.length && stop_point_names[i].downcase != "note" do
            service.stop_points << self.createStopPoint(stop_point_names[i], stop_point_locations[i])
            i += 1
          end
          service.save
        end

        #create_deployment_network_service_page(network.master.admin_site, network.deployment, network, service)

        #puts "Done Route and Service"
        if out == nil
          jptl_name  = "JPTL-#{File.basename(table_file)}"
          jptl_dname = File.join(File.dirname(table_file), jptl_name)
          fname      = File.join(dir, File.join(File.dirname(table_file), jptl_name))
          progress.log("Creating JPTLs in #{jptl_dname} for Direction #{direction} in file #{fname}")
          out = CSV.open(fname, "w", :force_quotes => true)
          progress.commit()
        end

        # position is the order of the JPTL in the JourneyPattern
        position   = 0
        last_stop  = nil
        start_time = nil
        last_time  = nil

        # Times start on Column D
        times      = cols.drop(3)

        progress.continue!

        progress.log("Service #{service.name}")
        progress.log("#{times.inspect}")
        progress.commit()

        # parse times and exit row if one is invalid
        parsed_times = []
        for i in 0..stop_point_names.size-1 do
          break if stop_point_names[i].downcase == "note"
          parsed_times << ((times[i] && !times[i].strip.blank?) ? parseTime(times[i]) : nil)
        end

        # The last column of the stop_point_names
        # *should be* NOTE and is and end marker
        # and therefore does not contain a time and
        # that is where we stop
        i = 0
        vehicle_journey = nil
        while i < stop_point_names.size
          if stop_point_names[i].downcase == "note"
            # We've got the note, regardless of extra columns, we end here.
            vehicle_journey.note = times[i]
            break
          end

          stop_name = stop_point_names[i]
          # We only do something if there is a time in the column
          if parsed_times[i] != nil

            if start_time == nil
              # This is the beginning point. The first time found.
              current_time  = parsed_times[i]
              start_time    = current_time
              timelit       = toTimelit(current_time)

              # There is a VehicleJourney and a JourneyPattern
              # for each line associated with this service.
              journey_index += 1

              # Both the JourneyPattern and VehicleJourney are persistent
              # by their constructed names.
              #puts "Getting Journey Pattern and VJ"
              @jv_lookup    = Time.now
              if !service.route
                raise "WTF 3 Route nil, Service #{service.name} #{i} #{stop_point_names[i]} #{times[i]}"
              end
              time_minutes = (start_time - Time.parse("0:00"))/60 # can be negative
              journey_pattern = service.get_journey_pattern(timelit, journey_index, table_file, file_line)
              vehicle_journey = create_vehicle_journey(network, service, journey_pattern, timelit, time_minutes)
              journey_pattern = vehicle_journey.journey_pattern

              #puts "Done Journey Pattern and VJ  #{Time.now - @jv_lookup}"
              # The JourneyPattern is persistent, and so are its JPTLs.
              # So we are replacing any previous JPTLs and regenerating them
              # in case we modified the stop points.
              #journey_pattern.journey_pattern_timing_links.destroy_all
              journey_pattern.journey_pattern_timing_links = []

              # Our starting StopPoint
              stop                                         = createStopPoint(stop_name, stop_point_locations[i])

              # Onto the rest
              last_time                                    = start_time
              last_stop                                    = stop
            else
              # If there is a time in this column (i), then we have a link from the
              # last location with a time.
              stop      = createStopPoint(stop_name, stop_point_locations[i])

              # Create the Link.
              jptl      = journey_pattern.get_journey_pattern_timing_link(position)
              jptl.from = last_stop
              jptl.to   = stop

              current_time = parsed_times[i]
              # time is stored in minutes the link takes to travel
              jptl.time    = (current_time-last_time)/60

              if jptl.time < 0
                jptl.time_issue = "#{table_file}:#{file_line}: Time issue #{current_time} is before the time of last JPTL #{last_time}"
              end

              # This is the initial path. May have to be modified,
              # which is why the JPTLs have persistent names.
              jptl.google_uri = constructGoogleMapURI(jptl.from.location, jptl.to.location)
              vpc             = cache.getViewPathCoordinates(jptl.google_uri)
              if !vpc
                jptl.path_issue            = "#{table_file}:#{file_line}: No valid path"
                jptl.view_path_coordinates = {"LonLat" => []}
                jptl.connect_endpoints_to_path()
              end
              jptl.view_path_coordinates = {"LonLat" => normalizePath(vpc["LonLat"])}
              if jptl.connect_endpoints_to_path()
                cs = jptl.view_path_coordinates["LonLat"]
                progress.log "Path Issue #{getGeoDistance(cs[0], cs[1])}"
                progress.log "Path Issue #{getGeoDistance(cs[cs.length-2], cs.last)}"
                jptl.path_issue = "#{table_file}:#{file_line}: Unconnected endpoints"
              end

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
                      jptl.to_kml]

              # Onto the next link, if any.
              position  += 1
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
        if (journey_pattern != nil)
          # Even if there is a consistency error, we still include it so that the
          # user can look at it.
          # TODO: We might mark a journey pattern as inconsistent so that it won't run.
          #service.journey_patterns << journey_pattern
          vehicle_journey.journey_pattern = journey_pattern
          vehicle_journey.display_name    = display_name
          vehicle_journey.path_issue      = journey_pattern.has_path_issues?
          vehicle_journey.csv_lineno      = file_line
          vehicle_journey.csv_filename    = table_file
          vehicle_journey.csv_row         = cols
          vehicle_journey.save!
          # autosave is false for vehicle_journey
          service.vehicle_journeys << vehicle_journey
          vehicle_journey.save!
          service.save!
          if (!vehicle_journey.journey_pattern.vehicle_journey)
            progress.error("journey_pattern.vehicle_journey is null! #{vehicle_journey.id}")
            progress.commit()
          end


          # We connect all paths to the endpoints. No need for more consitency checks.
          #error = vehicle_journey.journey_pattern.check_consistency
          #if error
          #  progress.error "Error in file #{table_file}: line #{file_line}: #{error}"
          #  progress.commit()
          #end
        end

        progress.continue!

      rescue ProcessingError => boom
        progress.error "#{table_file}:#{file_line}: #{boom}"
        progress.error "Line #{file_line} ignored: #{cols.inspect}"
        progress.commit()
      rescue JobAborted => abort
        raise abort
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
  def self.updateJPTLs(cache, network, dir, file, progress)
    jptl_dir = File.dirname(file)

    jptl_file = File.join(jptl_dir.sub(/^#{dir}/, "."), File.basename(file))
    begin
      tab = CSV.read(file, :col_sep => ",")
      progress.log "Processing  #{jptl_file} with comma separator."
    rescue Exception => boom
      begin
        tab = CSV.read(file, :col_sep => ";")
        progress.log "Processing  #{jptl_file} with semi-colon separator."
      rescue Exception => boom1
        progress.error("Could not read file #{jptl_file}. Separators must be comma or semi-colon. Skipping.")
        progress.commit()
      end
    end
    if tab.nil?
      return
    end
    progress.log("Potentially updating #{tab.count} JPTL links")
    progress.commit()
    lineno = 0
    for row in tab do
      lineo += 1
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
              vpc             = cache.getViewPathCoordinates(jptl.google_uri)
              if vpc != nil
                jptl.view_path_coordinates = { "LonLat" => normalizePath(vpc["LonLat"]) }
                if jptl.connect_endpoints_to_path()
                  jptl.path_issue = "#{jptl_file}:#{lineno}: Unconnected endpoints"
                else
                  jptl.path_issue = nil
                end
              end
              jptl.save!
            end
            vehicle_journey.path_issue = journey_pattern.has_path_issues?
          else
            progress.log("Cannot find Journey for #{row[0]} #{row[1]} #{row[2]}")
          end
          progress.commit()
        end
      end
    end
    return nil
  end

  #
  # This generates a hash structure that collects all files that do not
  # start with "JPTL-", which are the update files.  We use this to collect
  # the names, and just process the full list.
  #
  def self.dir_structure(dir, includeRE = nil, excludeRE = nil)
    # @param s [Object]
    # @param file [Object]
    def self.doit(s, file, includeRE, excludeRE)
      if (File.basename(file) =~ /^\./).nil?
        path = ::File.expand_path(File.join(s[:dir], file))
        if File.directory?(path)
          depth = s[:depth]
          dir = s[:dir]
          s[:depth] += 1
          s[:maxdepth] = [depth+1, s[:maxdepth]].max
          s[:files][ s[:depth] ] ||= []
          s[:dir] = path
          s =  Dir.entries(path).reduce(s) { |s,file| doit(s, file, includeRE, excludeRE) }
          s[:depth] = depth
          s[:dir] = dir
          return s
        end
        if (includeRE.nil? || File.basename(file) =~ includeRE) && (excludeRE.nil? || (File.basename(file) =~ excludeRE).nil?)
        #if (File.basename(file) =~ /^JPTL-/).nil? && !(File.basename(file) =~/\.csv$/).nil?
          s[:files][ s[:depth] ] << path
          return s
        end
      end
      return s
    end
    doit({:depth => -1, :maxdepth => 0, :files => [], :dir => "/"}, File.expand_path(dir), includeRE, excludeRE)
  end

  def self.processDirectory(cache, network, dir)
    progress = Progress.new(network)
    # First we must clear all Services, VehicleJourneys, and Routes.
    count = Route.where(:network_id => network.id).count
    progress.log "Destroying all routes (#{count}) in Network #{network.name}"
    Route.where(:network_id => network.id).each {|x| x.destroy }
    count = Service.where(:network_id => network.id).count
    if count > 0
      progress.log "Destroying #{count} left over Services"
      Service.where(:network_id => network.id).each {|x| x.destroy }
    end
    count = VehicleJourney.where(:network_id => network.id).count
    if count > 0
      progress.log "Destroying #{count} left over Journeys"
      VehicleJourney.where(:network_id => network.id).each {|x| x.destroy }
    end

    # That should do it.
    progress = Progress.new(network)
    progress.log("Processing Directory #{dir}")

    # Get all CSV files that do not start with JPTL
    s = self.dir_structure(dir, /\.[Cc][Ss][Vv]$/, /^JPTL-/)
    # Ah, we'll just process them flat.
    files = s[:files].flatten()
    nfiles = files.size
    progress.log("Directory Levels #{s[:maxdepth]+1} consisting of #{nfiles} files")
    ifile = 0
    files.each do |f|
      progress.progress(1, ifile, nfiles)
      ifile += 1
      begin
        progress.continue!
        self.generateJPTLs(cache, network, dir, f, progress)
      rescue ProcessingError => boom
        progress.error("#{boom}")
        progress.commit()
      rescue JobAborted => boom2
        progress.error("Job has been aborted")
        progress.commit()
        raise boom2
      rescue Exception => boom3
        p boom
        progress.error("#{boom3}")
        progress.error("Unrecoverable error. Exiting.")
        progress.error(boom3.backtrace.take(5).join(""))
        progress.commit()
        raise boom3
      end
    end

    issues_count = VehicleJourney.where(:network_id => network.id, :time_issue.ne => false).count
    progress.log "After processing, #{issues_count} Journeys have time issues."
    progress.commit()

  end

  def self.updateDirectory(cache, network, dir)
    progress = Progress.new(network)
    progress.log("Updating Directory #{dir}")

    s = self.dir_structure(dir, /^JPTL-\.*-fixed\.[Cc][Ss][Vv]$/)
    # Ah, we'll just process them flat.
    files = s[:files].flatten()
    nfiles = files.size
    progress.log("Directory Levels #{s[:maxdepth]+1} consisting of #{nfiles} files")
    ifile = 0
    files.each do |f|
      progress.progress(1, ifile, nfiles)
      ifile += 1
      begin
        progress.continue!
        self.updateJPTLs(cache, network, dir, f, progress)
      rescue ProcessingError => boom
        progress.error("#{boom}")
        progress.commit()
      rescue JobAborted => boom2
        progress.error("Job has been aborted")
        progress.commit()
        raise boom2
      rescue Exception => boom3
        p boom
        progress.error("#{boom3}")
        progress.error("Unrecoverable error. Exiting.")
        progress.error(boom3.backtrace.take(5).join(""))
        progress.commit()
        raise boom3
      end
    end

    issues_count = VehicleJourney.where(:network_id => network.id, :path_issue.ne => false).count
    progress.log "After processing, #{issues_count} Journeys have path issues."
    progress.commit()

  end

  def self.processNetwork(net, dir)
    cache = GoogleUriViewPath::Cache.new()
    processDirectory(cache, net, dir)
    updateDirectory(cache, net, dir)
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

  def self.generateRouteTableFiles(dir, route, progress)
    progress.commit()  if progress
    out = nil
    current_filename = nil
    for service in route.services do
      fname = File.join(dir, service.csv_filename)
      progress.log("Creating Route #{route.code} in #{fname}")
      if fname != current_filename
        out.close() if !out.nil?
        FileUtils.mkdir_p(File.dirname(fname))
        out = CSV.open(fname, "a+", :force_quotes => true)
      end
      out << ["Route Name", route.code, route.name, route.sort]
      out << ["Start Date", service.operating_period_start_date]
      out << ["End Date", service.operating_period_end_date]
      out << ["Direction", service.direction]
      row1 = ["Stop Points", "Days", "Display Name"]
      row2 = ["Locations", "", ""]
      for stop_point in service.stop_points do
        coords = stop_point.location.coordinates["LonLat"]
        row1 << stop_point.common_name
        row2 << "#{coords[0]},#{coords[1]}"
      end
      row1 << "NOTE"
      out << row1
      out << row2
      service.vehicle_journeys.order(:csv_lineno).each do   |vj|
        vjrow = [route.code, self.getNormalizedDayClass(service), vj.display_name]
        stop_points = service.stop_points
        index = 0

        jptls = vj.journey_pattern_timing_links
        time = vj.start_time

        while index < stop_points.length && !jptls[0].from.same?(stop_points[index])
          index += 1
          vjrow << ""
        end
        vjrow << toTimelit(Time.parse("0:00")+time, ".")
        time += jptls[0].time
        for jptl in jptls do
          index += 1
          while index < stop_points.length && !jptl.to.same?(stop_points[index])
            index += 1
            vjrow << ""
          end
          if index < stop_points.length
            vjrow << toTimelit(Time.parse("0:00")+time, ".")
            time = time + jptl.time
          end
        end
        vjrow << vj.note if vj.note
        out << vjrow
      end
    end
    out.close if !out.nil?
  end

  def self.generateJPTLFiles(dir, route, progress)
    progress.commit()  if progress
    out = nil
    current_filename = nil
    for service in route.services do
      bname = File.basename(service.csv_filename)
      dname = File.dirname(service.csv_filename)
      fname = "JPTL-" + bname.gsub(/\.[Cc][Ss][Vv]$/, "") + "-fixed.csv"
      fname = File.join(dir, File.join( dname, fname))
      progress.log("Creating JPTL fixed files for  #{route.code} in #{fname}")
      if fname != current_filename
        out.close() if !out.nil?
        FileUtils.mkdir_p(File.dirname(fname))
        out = CSV.open(fname, "w", :force_quotes => true)
      end
      service.vehicle_journeys.order(:csv_lineno).each do   |vj|
        vj.journey_pattern_timing_links.each do |jptl|
           row = [service.name,
                  vj.journey_pattern.name,
                  jptl.position,
                  jptl.from.common_name,
                  jptl.to.common_name,
                  jptl.to_kml]
           out << row
        end
      end
    end
    out.close if !out.nil?
  end

  def self.generateNetwork(dir, network, progress = nil)
    progress ||= NullProgress.new(network)
    for route in network.routes do
      self.generateRouteTableFiles(dir, route, progress)
      self.generateJPTLFiles(dir, route, progress)
    end
  end

  def self.generatePlanFile(network, progress = nil)
    dir = Dir.mktmpdir()
    generateNetwork(dir, network, progress)
    file = Tempfile.new(network.name)
    zip(network, file.path, dir)
    file.close
    return file.path
  end

  def self.zip(network, zip, dir)
    puts "ZIP IT #{dir}"
    Zip::Archive.open(zip, Zip::CREATE | Zip::TRUNC) do |zip_file|
      Dir.glob("#{dir}/**/*").each do |path|
        zpath = path.sub(/^#{dir}/, network.name)
        puts "zipping #{zpath} <- #{path}"
        if File.directory?(path)
          zip_file.add_dir(zpath)
        else
          zip_file.add_file(zpath, path)
        end
      end
    end
  end

end
