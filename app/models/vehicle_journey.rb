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

  key :csv,         Array # [String]
  key :line_no,     Integer
  key :filename,    String

  key :path_issue,  String

  belongs_to :service
  belongs_to :network
  belongs_to :master
  belongs_to :municipality

  one :journey_location, :dependent => :delete

  # Embedded
  one :journey_pattern, :autosave => true

  timestamps!

  ensure_index(:name, :unique => false)
  ensure_index(:persistentid, :unique => false)

  attr_accessible :name, :description, :departure_time, :display_name,
                  :persistentid, :slug,
                  :journey_pattern, :journey_pattern_id,
                  :master, :master_id,
                  :municipality, :municipality_id,
                  :network, :network_id,
                  :service, :service_id

  before_validation :ensure_slug

  validates_uniqueness_of :slug, :scope => [:network_id, :master_id, :municipality_id]
  validates_uniqueness_of :name, :scope => [:network_id, :master_id, :municipality_id]

  validates_presence_of :journey_pattern
  validates_presence_of :service
  validates_presence_of :departure_time

  validate :consistency_check

  before_save :make_id_name

  def consistency_check
    master == municipality.master &&
        master == network.master &&
        master == service.master &&
        municipality == network.municipality &&
        municipality == service.municipality &&
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
    ret.municipality = to_network.municipality

    ret.save!(:safe => true)
    ret
  end

  def route
    service.route
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

  def journey_pattern_timing_links
    journey_pattern.journey_pattern_timing_links
  end

  # Time is a time of day.
  def is_scheduled?(time)
    diff = (time-base_time)
    if (departure_time.minutes < diff && diff < departure_time.minutes + duration.minutes)
      return true
    else # it could be by a lot.
         #Say our base time ended up at midnight tomorrow becase it's after midnight
         # then our diff < -24 hourse
      diff = diff + 24.hours
      departure_time.minutes < diff && diff < departure_time.minutes + duration.minutes
    end
  end

  def locatedBy(coord)
    journey_pattern.locatedBy(coord)
  end

  def point_on_path(time_of_day)
    journey_pattern.point_on_path(time_of_day-(base_time+start_time.minutes))
  end

  #
  # Is the coordinate feasible given the specific time. If so, it returns it.
  # The coordinate mus be onRoute.
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

  def self.find_by_date(date, options = {})
    date = date.to_date

    day_field = DATE_FIELDS[date.wday]
    options = options.merge({
        :operating_period_start_date.lte => date.to_mongo,
        :operating_period_end_date.gte => date.to_mongo,
        day_field.to_sym => true
        })
    services = Service.where(options).all
    all = services.reduce([]) {|t,v| t + v.vehicle_journeys }
  end

  # Time is in minutes of midnight of the date. Be careful of TimeZone.
  def self.find_by_date_time(date, time, options = {})
    all = self.find_by_date(date, options)
    all.select { |vj| vj.is_scheduled?(time) }
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
  def stop_simulating
    logger.info "Being told to stop! #{name}"
    @please_stop_simulating = true
  end

  def time_zone
    return master.time_zone
  end

  def base_time
    Time.parse("0:00 #{time_zone}")
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
    simulate(time_interval, AuditLogger.new(STDOUT), clock)
  end

  #
  # This function figures out the next location information based
  # on the current distance traveled, the time and the last time
  # it was figured.
  # Parameters
  #  distance          The distance traveled
  #  tm_last         The time at distance
  #  tm_now          The time it is now
  #  tm_start        The time the route is supposed to start
  # Returns Hash
  #  :coord => The point on the route
  #  :distance => The new distance traveled
  #  :direction => The direction at distance
  #  :time => The time at new distance
  #  :ti_diff => The time interval from the last distance time
  #  :ti_offschedule => The time off schedule.
  #
  def figure_location(distance, tm_last, tm_now, tm_start)
    #p [tm_last, tm_now, tm_start]
    if (tm_now > tm_start) # or we have a Good Reported JourneyLocation.
                           # Maybe the bus is OnRoute sitting there waiting to go.
                           # We are operating.

      ti_diff = tm_now - tm_last
      estimate = journey_pattern.next_from(distance, ti_diff)
      estimate[:time] = tm_now
      estimate[:ti_diff] = ti_diff

      #Look for ReportedJourneyLocation
      rjls = ReportedJourneyLocation.find(:all,
                                          :conditions => {:vehicle_journey_id => self.id},
                                          :order => "reported_time, recorded_time")
      if (rjls == nil)
        return estimate
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
            :ti_diff        => tm_last - best.reported_time
        }
      else
        estimate[:reported] = false;
        estimate[:ti_offschedule] = tm_now - (tm_start + estimate[:ti_dist]),
            estimate[:ti_diff] = tm_last - tm_now
        ans = estimate
      end
      # Get rid of the processed reported journey locations.
      rjls.each { |r| r.delete }
      return ans
    else
      return nil
    end
  end

  def simulate(interval, logger = VehicleJourney.logger, clock = Time)
    tm_start = base_time + departure_time.minutes
    logger.info("Start Journey #{self.name} start #{tm_start} at #{tz(clock.now)}")

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
    while (distance < target_distance) do
      ans = figure_location(distance, tm_last, tm_now, tm_start)
      if (ans != nil)
        #logger.info "Journey '#{self.name}' answer #{ans[:coord]}"
        if journey_location == nil
          create_journey_location(:service => service, :route => service.route)
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
        distance = ans[:distance]
        logger.info "Journey '#{self.name}' location #{"%.5f, %.5f" % ans[:coord]} at #{tz(tm_now).strftime("%H:%M %Z")}"
      end
      tm_last = tm_now
      sleep interval
      tm_now = clock.now
      #logger.info("VehicleJourney '#{self.name}' tick #{tm_now} tm_start #{tm_start}")
      if @please_stop_simulating
        logger.info "Stopping #{self.name}"
        break
      end
      if @please_stop_simulating
        logger.info "Break didn't work: #{name}"
      end
    end
    logger.info "Ending Journey '#{self.name}' at #{distance} at #{tm_now}"
  rescue Exception => boom
    logger.info "Ending Journey '#{self.name}' because of #{html_escape(boom)}"
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
    attr_accessor :journey
    attr_accessor :runners
    attr_accessor :thread
    attr_accessor :time_interval
    attr_accessor :logger
    attr_accessor :clock

    def initialize(rs,j,t, clk = Time, logger = VehicleJourney.logger)
      @runners = rs
      @journey = j
      @time_interval = t
      @logger = logger
      @clock = clk
      #logger.info "Initializing Journey #{journey.name}"
    end

    def run
      logger.info "Starting Journey #{journey.name}"
      thread = Thread.new do
        begin
          journey.simulate(time_interval, logger, clock)
          logger.info "Journey ended normally #{journey.name}"
        rescue Exception => boom
          logger.info "Stopping Journey #{journey.name} on #{VehicleJourney.html_escape(boom)}"
        ensure
          logger.info "Removing Journey #{journey.name}"
          runners.delete(journey.id)
        end
      end
      self
    end
  end

  # Simulates all the appropriate vehicle journeys updating locations
  # on the time_interval. The active journey list checked every 60
  # seconds. An exception delivered to this function will end the
  # simulation of all running journeys.
  def self.simulate_all(find_interval, time_interval, time = Time.now, mult = 1, duration = -1, options = {})
    clock = BaseTime.new(time, mult)
    job = SimulateJob.first(options)
    logger.info "Starting for #{job.name}"
    logger = job
    logical_start_time = clock.now
    begin
      job.sim_time = time
      job.clock_mult = mult
      job.processing_started_at = Time.now
      job.processing_completed_at = nil
      job.set_processing_status!("Running")
      JourneyLocation.where(options).all.each {|x| x.delete() }
      runners = {}
      while (x = SimulateJob.first(options)) && !x.please_stop && (duration < 0 || (clock.now - logical_start_time) <= duration.minutes) do
        date = time = clock.now
        journeys = VehicleJourney.find_by_date_time(date, time, options)
        logger.info "Found #{journeys.length} journeys at #{date.in_time_zone(job.master.time_zone).strftime("%m-%d-%Y")} #{time.in_time_zone(job.master.time_zone).strftime("%H:%M %Z")}"
        # Create Journey Runners for new Journeys.
        for j in journeys do
          if !runners.keys.include?(j.id)
            runners[j.id] = JourneyRunner.new(runners,j,time_interval, clock, logger).run
          end
        end
        sleep find_interval
      end
    rescue Exception => boom
      job.set_processing_status!("Stopping")
      logger.info "Ending because #{html_escape(boom)}"
      #logger.info boom.backtrace.join("\n")
    ensure
      job.set_processing_status!("Stopping")
      logger.info "Stopping for #{job.name} with #{runners.keys.size} Runners"
      keys = runners.keys.clone
      for k in keys do
        runner = runners[k]
        if runner != nil
          #logger.info "Killing #{runner.journey.id} #{runner.journey.id} thread = #{runner.journey.id}"
          if runner.journey != nil
            runner.journey.stop_simulating
          end
        end
      end
      logger.info "Waiting"
      while !runners.empty? do
        logger.info "#{runners.keys.size} Runners"
        sleep time_interval
      end
      logger.info "All stopped"
      job.processing_completed_at = Time.now
      job.set_processing_status!("Stopped")
    end
  end


end
