class VehicleJourney
  include MongoMapper::Document
  include LocationBoxing
  plugin MongoMapper::Plugins::IdentityMap

  key :name,        String
  key :description, String
  key :departure_time, Integer # in minutes from midnight
  key :display_name, String
  key :persistentid, String
  key :note,         String
  key :days,          String
  key :slug,         String

  key :csv_row,         Array # [Strings and Numbers]
  key :csv_lineno,     Integer
  key :csv_filename,    String

  key :path_issue,  Boolean, :default => false
  key :time_issue,  Boolean, :default => false
  key :time_issues,  Array # String

  # Searchable indicator if path has been updated manually.
  key :path_changed, Boolean, :default => false

  belongs_to :route
  belongs_to :service
  belongs_to :network
  belongs_to :master
  belongs_to :deployment

  many :reported_journey_locations, :dependent => :delete

  # Embedded
  one :journey_pattern, :autosave => true

  timestamps!

  ensure_index(:name, :unique => false)
  ensure_index(:persistentid, :unique => false)

  attr_accessible :name, :description, :departure_time, :display_name,
                  :persistentid, :slug,
                  :journey_pattern, :journey_pattern_id,
                  :master, :master_id,
                  :deployment, :deployment_id,
                  :network, :network_id,
                  :service, :service_id,
                  :route, :route_id

  before_validation :ensure_slug

  validates_uniqueness_of :slug, :scope => [:network_id, :master_id, :deployment_id]
  validates_uniqueness_of :name, :scope => [:network_id, :master_id, :deployment_id]

  validates_presence_of :journey_pattern
  validates_presence_of :service
  validates_presence_of :departure_time

  validate :consistency_check

  before_save :make_id_name

  def consistency_check
    master == deployment.master &&
        master == network.master &&
        master == service.master &&
        deployment == network.deployment &&
        deployment == service.deployment &&
        network == service.network
  end

  # This method assumes that the service and network have
  # already been copied.
  def copy!(to_service, to_network)
    ret              = VehicleJourney.new(self.attributes)

    # TODO: Does the journey_pattern get copied here?

    # Master should already be the same.
    ret.service      = to_service
    ret.network      = to_network
    ret.master       = to_network.master
    ret.deployment = to_network.deployment

    ret.save!(:safe => true)
    ret
  end

  def self.find_by_routes(routes)
    self.joins(:journey_pattern).where(:journey_patterns => {:route_id => routes})
  end

  def make_id_name
    persistentid = name.hash.abs
  end

  def check_name
    #puts "AfterSAVE  id #{persistentid} hash #{name.hash.abs} name #{name}"
  end

  # Minutes from Midnight
  def start_time
    departure_time
  end

  def duration
    journey_pattern.duration
  end

  # Minutes from Midnight
  def end_time
    start_time + duration
  end

  def stop_points
    journey_pattern.stop_points
  end

  # TODO: There is an issue where we are planing in Daylight Savings Time and switching to Standard Time.
  def time_start(position = 0)
    time = base_time + departure_time.minutes
    i = 0
    while i < position
      time += journey_pattern_timing_links[i].time.minutes
      i += 1
    end
    return time
  end

  def time_end(position = -1)
    # -1 means the end of last timing link
    raise "bad position" if position >= journey_pattern_timing_links.size
    position = journey_pattern_timing_links.size-1 if position == -1
    time = time_start
    i = 0
    while i <= position
      time += journey_pattern_timing_links[i].time.minutes
      i += 1
    end
    return time
  end

  def time_start_lit(position = 0)
    minutes = departure_time
    i = 0
    while i < position
      minutes += journey_pattern_timing_links[i].time
      i += 1
    end
    return ServiceTable.minutesToTimelit(minutes)
  end

  def time_end_lit(position = -1)
    # -1 means the end of last timing link
    raise "bad position" if position >= journey_pattern_timing_links.size
    position = journey_pattern_timing_links.size-1 if position == -1
    minutes = departure_time
    i = 0
    while i <= position
      minutes += journey_pattern_timing_links[i].time
      i += 1
    end
    return ServiceTable.minutesToTimelit(minutes)
  end

  def journey_pattern_timing_links
    journey_pattern.journey_pattern_timing_links
  end

  # Time is a time of day.
  def is_scheduled?(base_time, time)
    diff = (time-base_time)
    if (departure_time.minutes < diff && diff < departure_time.minutes + duration.minutes)
      return true
    else # it could be by a lot.
         #Say our base time ended up at midnight tomorrow because it's after midnight
         # then our diff < -24 hours
      diff = diff + 24.hours
      departure_time.minutes < diff && diff < departure_time.minutes + duration.minutes
    end
  end

  #
  # Determines if a Journey is "active", which means it should be displayed in the device
  # for drivers and passengers to report on. It might be sitting awaiting to leave before
  # its start time, or be on route from the garage and the driver wants to set it before.
  # It could also be late with passengers reporting on it theoretically after it finished
  # its simulation.  Time is the time of day, and thresholds are in minutes.
  #
  def is_active?(base_time, time, before_threshold = 10, after_threshold = before_threshold)
    is_scheduled?(base_time, time + before_threshold.minutes) || is_scheduled?(base_time, time - after_threshold.minutes)
  end

  def locatedBy(coord)
    journey_pattern.locatedBy(coord)
  end

  def point_on_path(time_of_day)
    journey_pattern.point_on_path(time_of_day-(base_time+start_time.minutes))
  end

  #
  # Is the coordinate feasible given the specific time. If so, it returns it.
  # The coordinate must be onRoute.
  # DateTime is the time of day. Time.now format.
  # earlybuf and latebuf are int or float repesenting minutes
  # earlybuf should be negative.
  #
  def is_feasible?(coord, date_time, earlybuf, latebuf)
    time_on_path = date_time - (base_time + start_time.minutes)
    pts = journey_pattern.get_possible(coord, 60)
    for p in pts do
      if (time_on_path + earlybuf.minutes  < p[:ti_dist] && p[:ti_dist] <= time_on_path + latebuf.minutes)
        return p
      end
    end
    return false
  end

  ##
  # Returns the direction in radians from north that a bus on a particular
  # link will be going at a particular location near that link
  #
  def direction(coord, buffer, time)
    tls = journey_pattern.journey_pattern_timing_links
    begin_time = base_time + departure_time.minutes
    for tl in tls do
      end_time = begin_time + tl.time.minutes
      if (begin_time - 10.minutes <= time && time <= end_time + 10.minutes)
        if tl.isBoundedBy(coord)
          begin
            return tl.direction(coord, buffer)
          rescue
            # Not on Link, but it could be on another link that is bounded in.
          end
        end
      end
      begin_time = end_time
    end
    raise Not on Pattern
  end

  # Returns the time difference in minutes
  # Negative is early.
  def time_difference(distance, time)
    etd = base_time + departure_time.minutes
    eta = etd + journey_pattern.time_on_path(distance)
    if eta - 1.minute <= time
      if time <= eta + 1.minute
        # We are for the most part, on time
        return 0;
      else
        logger.info "LATE!!!!  #{tz(time)} ETA #{tz(eta)}  #{time-eta}  #{((time - eta)/1.minute).to_i}"
        # we are late (positive) in minutes
        return ((time - eta)/1.minute).to_i
      end
    else
      logger.info "EARLY!!!  #{tz(time)} ETA #{tz(eta)}  #{time-eta}  #{((time - eta)/1.minute).to_i}"
      # We are early (negative)
      return ((time - eta)/1.minute).to_i
    end
  end

  def ensure_slug
    self.slug = self.name.to_url()
  end

  ##
  # Finding the JourneyLocations
  #

  DATE_FIELDS = [ "sunday", "monday", "tuesday", "wednesday", "thursday", "friday", "saturday" ]

  #
  def self.find_by_date(date, options = {})
    date = date.to_date

    day_field = DATE_FIELDS[date.wday]
    options = options.merge({
        :operating_period_start_date.lte => date.to_mongo,
        :operating_period_end_date.gte => date.to_mongo,
        day_field.to_sym => true})
    services = Service.where(options).all
    ret = services.reduce([]) {|t,v| t + v.vehicle_journeys }
  end

  # Time is in minutes of midnight of the date. Be careful of TimeZone.
  def self.find_by_date_time(date, time, options = { })
    ret = self.find_by_date(date, options)
    ret.select { |vj| vj.is_scheduled?(date, time) }
  end

  # Time is in minutes of midnight of the date. Be careful of TimeZone.
  def self.find_actives_by_date_time(date, time, options = { })
    ret = self.find_by_date(date, options)
    # Looking for 10 minutes before start and 30 minutes late.
    ret.select { |vj| vj.is_active?(date, time, 10, 20) }
  end

  def self.find_or_initialize(options)
    vj = VehicleJourney.where(options).first
    vj ||= VehicleJourney.new(options)
  end

  def self.html_escape(s)
    s.to_s.gsub(/&/, "&amp;").gsub(/\"/, "&quot;").gsub(/>/, "&gt;").gsub(/</, "&lt;")
  end

  ############################################################################
  # Simulations
  ############################################################################

  # This function sets a indication so that the simulation for the
  # this journey stops on the next wake up call.

  def prepare_simulation
    @please_stop_simulating = false;
  end

  def stop_simulating
    logger.info "Being told to stop! #{name}"
    @please_stop_simulating = true
  end

  def time_zone
    return master.time_zone
  end

  def base_time(reference = Time.now)
    # This allows us to account for Daylight Savings Time at "now"
    offset = Timezone::Zone.new(:zone => time_zone).utc_offset(reference)
    # We get the right offset for the reference datetime, then we get midnight of that day
    # at the proper offset. This matters with Daylight Savings Time. See, is_scheduled?
    timelit = tz(reference).strftime("%Y-%m-%d 0:00 %z")
    Time.parse(timelit)
  end

  def tz(time)
    time.in_time_zone(time_zone)
  end

  class AuditLogger < Logger
    def format_message(severity, timestamp, progname, msg)
      "#{msg}\n"
    end
  end

  logger = AuditLogger.new(STDERR)

  class BaseTime
    def initialize(basetime, mult = 1)
      @mult = mult
      @basetime = basetime
      @tm = Time.now
    end

    def now
      @basetime + (Time.now - @tm) * @mult
    end
  end

  def simulate_self(time_interval)
    clock = BaseTime.new(base_time+departure_time.minutes-1.minutes)
    active_journey = ActiveJourney.new()
    simulate( time_interval, active_journey, base_time, nil, AuditLogger.new(STDOUT), clock)
    # We didn't save the ActiveJourney.
  end

  #
  # This function figures out the next location information based
  # on the current distance traveled, the time and the last time
  # it was figured.
  # Parameters
  #  disposition     The disposition, active, test, or simulate.
  #  distance        The distance traveled
  #  tm_last         The time at distance
  #  tm_now          The time it is now
  #  tm_start        The time the route is supposed to start
  #  location        The last reported or estimated location.
  # Returns Hash
  #  :coord => The point on the route
  #  :distance => The new distance traveled
  #  :direction => The direction at distance
  #  :time => The time at new distance
  #  :ti_diff => The time interval from the last distance time
  #  :ti_offschedule => The time off schedule.
  #
  def figure_location(disposition, distance, tm_last, tm_now, tm_start, location)
    force_estimate = false
    #p [tm_last, tm_now, tm_start]
    if (tm_now > tm_start) # or we have a Good Reported JourneyLocation.
                           # Maybe the bus is OnRoute sitting there waiting to go.
                           # We are operating.
      if (distance == 0)   # journey_location.nil? || journey_location.distance == 0
        # We haven't started yet, we need first estimate
        ti_diff = tm_now - tm_start
      else
        ti_diff = tm_now - tm_last
      end

      estimate = journey_pattern.next_from(distance, ti_diff)
      estimate[:time] = tm_now
      estimate[:ti_diff] = ti_diff

      # We are into the schedule, force the estimate below if we have no reported locations.
      force_estimate = true
    else  # tm_now <= tm_start
      # This whole branch deals with before the journey is supposed to start.
      # We may have a reported location:
      #   Driver on the way to the first stop
      #   Passenger sitting on bus at stop before it moves.
      if distance == 0
        # Our estimate is merely sitting at the beginning of the route.
        estimate = journey_pattern.next_from(0, 0)
        estimate[:time] = tm_now
        estimate[:ti_diff] = 0
      elsif distance > 0 # ==> location != nil
        # our estimate is that the bus isn't going to move. It just got started early, hope it will slow down
        # from start
        estimate = journey_pattern.next_from(distance,0)
        estimate[:time] = tm_now
        estimate[:ti_diff] = 0
        # We've already started, location should be non-nul
        force_estimate = true

        # We could be ahead of schedule here based on earlier reported locations
      else # distance < 0
        # Don't know if we should get here. We'll just estimate from the beginning.
        estimate        = journey_pattern.next_from(0, 0)
        estimate[:time] = tm_now
        estimate[:ti_diff] = 0
      end
    end

    #Look for ReportedJourneyLocation
    rjls = reported_journey_locations.where(:disposition => disposition).order(:reported_time, :recorded_time).all

    if (rjls.nil? || rjls.empty?)
      # If we have not previously saved a journey location, we haven't started yet, so dont report out
      # estimate up as a reported location.
      if force_estimate
        return estimate
      else
        return nil
      end
    end

    nrjls = []
    for rjl in rjls do
      ans = journey_pattern.get_possible(rjl.location, 60)
      p ans
      for a in ans do
        #p [(tm_last-tm_start)-2.minutes, a[:ti_dist], (tm_now-tm_start)+1.minute]
        if (tm_last-tm_start-2.minutes) <= a[:ti_dist] && a[:ti_dist] <= (tm_now-tm_start+1.minute)
          rjl.location_info = a;
          nrjls += [rjl]
        end
      end
    end
    count = nrjls.size
    # Make two Vectors, reported_time and distance
    a,b = nrjls.reduce([[tm_last.to_i],[distance]]) { |a,rjl| [a[0] += [rjl.reported_time.to_i], a[1] += [rjl.distance]] }
    # Simply, right now we figure the correlation to reported times and distances.
    # We'll get the one with the least variance from the line.
    simple_regression = Statsample::Regression.simple(a.to_scale(),b.to_scale())
    best = nil
    #p estimate
    for rjl in nrjls do
      #p [distance, rjl.distance, estimate[:distance]]
      if (distance < rjl.distance)
        # We have a good confidence if the reported time is in line
        # with the estimated time.
        if (tm_last < rjl.reported_time && tm_now > rjl.reported_time)
          # We check the recorded time.
          rjl.variance = (simple_regression.x(rjl.reported_time.to_i)-rjl.distance)**2
          # and something indicating closemess to the tm_now.
          rjl.variance *= 1 + (tm_now - rjl.reported_time)
          #p [best != nil ? best.variance : nil, rjl.variance]
          if (best == nil || rjl.variance < best.variance)
            best = rjl
            best.off_schedule = best.reported_time - (tm_start + rjl.location_info[:ti_dist])
          end
        end
      end
    end
    if (best != nil)
      ans = {
          :reported       => true,
          :variance       => best.variance,
          :distance       => best.distance,
          :direction      => best.direction,
          :coord          => best.location,
          :speed          => best.speed,
          :time           => best.reported_time,
          :ti_offschedule => best.off_schedule,
          :ti_diff        => best.reported_time - tm_last
      }
    else
      estimate[:reported] = false
      estimate[:ti_offschedule] = tm_now - (tm_start + estimate[:ti_dist]),
      estimate[:ti_diff] = tm_now - tm_last
      ans = estimate
    end
    # Get rid of the processed reported journey locations.
    rjls.each { |r| r.delete }
    return ans
  end

  def simulate(interval, active_journey, base_time, job = nil, logger = VehicleJourney.logger, clock = Time)
    journey_location = nil
    disp = job ? job.disposition : "simulate"

    tm_start = base_time + departure_time.minutes
    logger.info("Start Journey #{self.name} base #{base_time.strftime("%Y-%m-%d")} start #{tm_start.strftime("%H:%M %Z")} at #{tz(clock.now)}")

    # Since we are working with time intervals, we get our current time base.
    tm_base = clock.now

    # The base time may be midnight of the next day due to TimeZone.
    # If so the time_from_midnight will be negative. However, before we
    # add 24 hours to it, we check to see if we are scheduled within
    # a negative departure time (before midnight).
    ti_from_midnight = tm_base - base_time
    if (departure_time <= 0 && departure_time.minutes <= ti_from_midnight &&
        ti_from_midnight <= departure_time.minutes + duration.minutes)
      tm_start = tm_start + 24.hours
    end

    target_distance = journey_pattern.path_distance
    #logger.info("#{self.name} start #{tm_start} for #{departure_time} after #{base_time} path_distance #{target_distance}")
    distance = 0.0
    tm_last = tm_base
    tm_now = tm_base
    first_answer = true
    journey_location = nil
    #
    # TODO: Loop should continue past target_distance See below;
    # We want to keep this simulation running until we get a verifiable report that the bus has stopped.
    # We may have simulated past the end of the route, but suddenly get a reported location as it is late.
    #
    # What happens otherwise, is we get a FIRST location each time and the distance is past the target_distance
    # and it ends normally, only to be picked up again by simulate_all, looking for actives.
    # TOO: We should incorporate into ActiveJourney whether this route has completed its journey.
    #
    while (distance < target_distance) do
      ans = figure_location(disp, distance, tm_last, tm_now, tm_start, journey_location)
      if (ans != nil)
        #logger.info "Journey #{self.name} answer #{ans[:coord]}"
        if journey_location.nil?
          logger.info "Journey #{self.name} FIRST location #{"%.5f, %.5f" % ans[:coord]} at #{tz(tm_now).strftime("%H:%M:%S %Z")}"
          journey_location = active_journey.make_journey_location()
        else
          journey_location.last_coordinates   = journey_location.coordinates
          journey_location.last_reported_time = journey_location.reported_time
          journey_location.last_distance      = journey_location.distance
          journey_location.last_direction     = journey_location.direction
          journey_location.last_timediff      = journey_location.timediff
        end
        journey_location.coordinates   = ans[:coord]
        journey_location.direction     = ans[:direction]
        journey_location.distance      = ans[:distance]
        journey_location.timediff      = ans[:ti_diff]
        journey_location.reported_time = ans[:time]
        journey_location.recorded_time = clock.now

        journey_location.save!
        if first_answer
          # We do this here instead of when we create journey_location, because we don't want one
          # in the DB without any info. The active_journey.save would automatically save the
          # attached journey_location.
          active_journey.time_start = ans[:time]
          active_journey.time_on_route = ans[:ti_diff]
          active_journey.current_distance = ans[:distance]
          active_journey.save
          first_answer = false
        else
          active_journey.time_on_route += ans[:ti_diff]
          active_journey.current_distance = ans[:distance]
          active_journey.save
        end
        distance = ans[:distance]
        logger.info "Journey #{self.name} location #{"%.5f, %.5f" % ans[:coord]} at #{tz(tm_now).strftime("%H:%M:%S %Z")} time #{active_journey.time_on_route} dist #{distance.floor}"
      else
        logger.info("No answer #{self.name} -- tm_now #{tm_now} tm_start #{tm_start} = should get ans #{tm_now > tm_start}" )  if tm_now > tm_start
      end
      tm_last = tm_now
      sleep interval
      tm_now = clock.now
      #logger.info("VehicleJourney '#{self.name}' tick #{tm_now} tm_start #{tm_start}")
      if @please_stop_simulating || (job && (job = job.reload).nil? || job.please_stop || job.delayed_job.nil?)
        logger.info "Forced Stop #{self.name}"
        break
      end
    end
    logger.info "End Journey '#{self.name}' at #{distance.floor} at #{tm_now}"
  rescue Exception => boom
    logger.info "Ending Journey '#{self.name}' because of #{VehicleJourney.html_escape(boom)}"
    #logger.info boom.backtrace
  ensure
    if journey_location != nil
      journey_location.destroy
      # The following reloads so that the relationship between this object and
      # journey token is unfrozen, otherwise error "cant modify frozen hash" TypeError happens.
      self.reload
    end
  end

  #---------------------------------------------------
  # Simulator for all VehicleJourneys
  # Run from a Console or Background Process
  #---------------------------------------------------
  # TODO: Make #puts calls to log

  class JourneyRunner
    attr_accessor :base_date
    attr_accessor :journey
    attr_accessor :runners
    attr_accessor :thread
    attr_accessor :time_interval
    attr_accessor :logger
    attr_accessor :clock
    attr_accessor :job
    attr_accessor :key

    def initialize(rs,key, job, bd, j,t, clk = Time, logger = VehicleJourney.logger)
      @base_date = bd
      @key = key
      @runners = rs
      @journey = j
      @time_interval = t
      @logger = logger
      @clock = clk
      @job = job
      #logger.info "Initializing Journey #{journey.name}"
    end

    def stop
      # Somebody may have removed the journey before they stopped the job
      journey.stop_simulating if journey
    end

    def run
      thread = Thread.new do
        journey.prepare_simulation
        active_journey = ActiveJourney.new()
        begin
          logger.info "Begin Active Journey #{journey.name} dist #{journey.journey_pattern.path_distance.floor} start #{journey.start_time} dur #{journey.duration} at #{clock.now}"
          active_journey.vehicle_journey = journey
          active_journey.deployment = job.deployment
          active_journey.service = journey.service
          active_journey.route = journey.service.route
          active_journey.disposition = job.disposition
          active_journey.simulate_job = job
          active_journey.master = job.master
          active_journey.save

          journey.simulate(time_interval, active_journey, base_date, job, logger, clock)
        rescue Exception => boom
          logger.info "Error: Active Journey #{journey.name} ended because #{VehicleJourney.html_escape(boom)}"
        ensure
          logger.info "End Active Journey #{journey.name}"
          active_journey.destroy
          runners.delete(key)
        end
      end
      self
    end
  end

  # Simulates all the appropriate vehicle journeys updating locations
  # on the time_interval. The active journey list checked every 60
  # seconds. An exception delivered to this function will end the
  # simulation of all running journeys.
  def self.simulate_all(job_id, find_interval, time_interval, time = Time.now, mult = 1, duration = -1)
    logger = job = SimulateJob.find(job_id)
    clock = BaseTime.new(time, mult)
    logical_start_time = clock.now
    # logger.info "Starting for #{job.name} in #{job.master.name} at #{logical_start_time}"
    begin
      job.sim_time = time
      job.clock_mult = mult
      job.processing_started_at = Time.now
      job.processing_completed_at = nil
      job.set_processing_status!("Running")
      # We need to delete any of this disposition.
      if (job.disposition == "active" || job.disposition == "test")
        # These can be left over from old jobs that got removed.
        ActiveJourney.where(:master_id => job.master.id, :disposition => job.disposition).each {|x| x.destroy()}
      end
      # simulate will just be
      ActiveJourney.where(:simulate_job => job.id).all.each {|x| x.destroy() }
      runners = {}
      while (x = SimulateJob.find(job_id)) && !x.please_stop && (duration < 0 || (clock.now - logical_start_time) <= duration.minutes) do
        time = clock.now
        date = job.master.base_time(time)

        # And all the journeys from today. Note, it is quite possible to get the same journey for both dates.
        # However, unless a journey runs for close to 24 hours, we'd end up with both. However, we prefix
        # the index key with the base date. TODO: This could lead to problems with ActiveJourney since we'd
        # end up with the same journey. However, the journey duration would have to be 7200 minutes or more.
        # TODO: make sure duration cannot be that?

        # Get all Journeys that might be on yesterdays base time.
        b_date = date - 1.day
        b_journeys = VehicleJourney.find_actives_by_date_time(b_date, time, { :master_id => job.master.id, :deployment_id => job.deployment.id })
        journeys = VehicleJourney.find_actives_by_date_time(date, time, { :master_id => job.master.id, :deployment_id => job.deployment.id })
        logger.info "Found #{b_journeys.length + journeys.length} Active Journeys at #{date.in_time_zone(job.master.time_zone).strftime("%Y-%m-%d")} #{time.in_time_zone(job.master.time_zone).strftime("%H:%M:%S %Z")}"

        # Create Journey Runners for new Journeys.
        for j in b_journeys do
          key = "#{b_date}:#{j.id}"
          if !runners.keys.include?(key)
            runners[key] = JourneyRunner.new(runners, key, job, b_date, j, time_interval, clock, logger).run
          end
        end

        # Create Journey Runners for new Journeys.
        for j in journeys do
          key = "#{date}:#{j.id}"
          if !runners.keys.include?(key)
            runners[key] = JourneyRunner.new(runners, key, job, date, j, time_interval, clock, logger).run
          end
        end
        sleep find_interval
      end
    rescue Exception => boom
      job = SimulateJob.find(job_id)
      if job
        job.set_processing_status!("Stopping")
        logger.info "Error: Ending Job because #{VehicleJourney.html_escape(boom)}"
        logger.info boom.backtrace.take(10).join("\n")
      end
    ensure
      job = SimulateJob.find(job_id)
      if job
        job.set_processing_status!("Stopping")
        logger.info "Stopping #{job.name} with #{runners.keys.size} Runners"
        keys = runners.keys.clone
      end
      for k in keys do
        runner = runners[k]
        if runner != nil
          runner.stop
        end
      end
      if job
        logger.info "Waiting for journey runners to end gracefully." if runners.keys.size > 0
        while !runners.empty? do
          logger.info "#{runners.keys.size} Runners"
          sleep time_interval
        end
        logger.info "All stopped"
        job.processing_completed_at = Time.now
        job.set_processing_status!("Stopped")
      else
        raise "Aborted!"
      end
    end
  end


end
