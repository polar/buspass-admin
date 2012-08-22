##
# Service
#   This class represents the Service Parameters for a particular Route.
#
class Service
  include MongoMapper::Document
  plugin MongoMapper::Plugins::IdentityMap

  belongs_to :route
  belongs_to :network
  belongs_to :deployment
  belongs_to :master

  key :name,     String

  key :operating_period_start_date, Date
  key :operating_period_end_date,   Date

  key :monday,    Boolean
  key :tuesday,   Boolean
  key :wednesday, Boolean
  key :thursday,  Boolean
  key :friday,    Boolean
  key :saturday,  Boolean
  key :sunday,    Boolean

  key :direction, String
  key :day_class, String
  key :slug,      String

  key :csv_stop_point_names, Array # [String]
  key :csv_lineno,           Integer
  key :csv_locations,        Array # [String]
  key :csv_filename,         String

  # Embedded
  many :stop_points

  timestamps!

  ensure_index(:name, :unique => false)

  attr_accessible :name, :operating_period_end_date, :operating_period_start_date, :direction, :day_class, :slug,
                  :route, :route_id,
                  :network, :network_id,
                  :master, :master_id,
                  :deployment, :deployment_id,
                  :csv_stop_point_names,
                  :csv_lineno,
                  :csv_locations,
                  :csv_filename

=begin
  validates_date :operating_period_start_date
  validates_date :operating_period_end_date,
                 :after => :operating_period_start_date
                 :after_message => "end date must be after start date"
=end

  before_validation :day_class_sync
  before_validation :ensure_slug

  def day_class_sync
    self.setOperatingDays(day_class)
  end

  def copy!(to_route, to_network)
    ret = Service.new(self.attributes)

    ret.route        = to_route
    ret.network      = to_network
    ret.master       = to_network.master
    ret.deployment = to_network.deployment

    ret.save!(:safe => true)
    ret
  end

  #
  # Currently, journey patterns are not shared, and neither
  # are their timing links.
  #
  #many :journey_patterns, :dependent => :destroy
  many :vehicle_journeys, :dependent => :destroy, :autosave => false

  def journey_patterns
    vehicle_journeys.map {|s| s.journey_pattern}
  end

  #
  # The constructed name of a service is unique so it can be a persistent id
  # as well. That means we can update it from a CSV file.  Example:
  #  Route {code} {Weekday|Daily|Saturday|Sunday|Weekend} {Inbound|Outbound} Service <StartDate> to <EndDate>
  #
  # Network is unique to Master and Deployment.
  validates_uniqueness_of :name, :scope => [:network_id, :master_id, :deployment_id]
  validates_uniqueness_of :slug, :scope => [:network_id, :master_id, :deployment_id]

  validates_presence_of :network
  validates_presence_of :master
  validates_presence_of :deployment
  validates_presence_of :route

  def self.find_or_create_by_route(route, direction, designator, start_date, end_date)
    sd = start_date.strftime("%Y-%m-%d")
    ed = end_date.strftime("%Y-%m-%d")
    name = "Route #{route.code} #{designator} #{direction} #{sd} to #{ed}"
    #puts "Service query"
    s = Service.first(:network_id => route.network.id, :name => name)
    #puts s ? "Found" : "creating......"
    if s.nil?

      # Just make sure.
      route.save!(:safe => true)
      s = Service.new(:network => route.network,
                      :master => route.network.master,
                      :deployment => route.network.deployment,
                      :name => name,
                      :operating_period_start_date => start_date,
                      :operating_period_end_date => end_date,
                      :day_class => designator,
                      :direction => direction,
                      :route => route)
      #puts "Service saving...."
      s.save!(:safe => true)
      if s.route != route
        raise "DB Problem 1 Service Route doesn't contain the correct route! #{s.route}"
      end
    end
    if s.route != route
      raise "DB Problem 2 Service Route doesn't contain the correct route! #{s.route}"
    end
    #puts "Service Done"
    return s
  end

  def locatedBy(location)
    journey_patterns.reduce(false) {|v,tl| v || tl.locatedBy(coord) }
  end

  def setOperatingDays(designator)
    self.day_class = designator

    self.monday    = false
    self.tuesday   = false
    self.wednesday = false
    self.thursday  = false
    self.friday    = false
    self.saturday  = false
    self.sunday    = false

    items = designator.split(",").collect { |s| s.strip.downcase }
    items.each do |item|
      case item
        when "monday", "m", "mon"
          self.monday = true
        when "tuesday", "t", "tu" "tue"
          self.tuesday = true
        when "wednesday", "w", "wWed"
          self.wednesday = true
        when "thursday", "th", "thu"
          self.thursday = true
        when "friday", "f", "fri"
          self.friday = true
        when "saturday", "s", "sat"
          self.saturday = true
        when "sunday", "su", 'sun'
          self.sunday = true
        when "weekday"
          self.monday    = true
          self.tuesday   = true
          self.wednesday = true
          self.thursday  = true
          self.friday    = true
        when "daily", "d"
          self.monday    = true
          self.tuesday   = true
          self.wednesday = true
          self.thursday  = true
          self.friday    = true
          self.saturday  = true
          self.sunday    = true
        when "weekend"
          self.saturday = true
          self.sunday   = true
        when "mon-thurs"
          self.monday    = true
          self.tuesday   = true
          self.wednesday = true
          self.thursday  = true
        when "mwf"
          self.monday    = true
          self.wednesday = true
          self.friday    = true
        else # skip it.
      end
    end
  end

  def is_operational?(date)
    date = date.to_date
    today = DATE_FIELDS[date.wday]
    read_attribute(today) && operating_period_start_date <= date && date <= operating_period_end_date
  end

  ##
  # We create a JourneyPattern with a readable name for route, day_class, and direction.
  # The given index should make the name unique.
  #
  # @param time [Time]
  # @param index [Integer]
  # @param csv_file [File]
  # @param csv_file_lineno [Integer]
  #
  # @returns [JourneyPattern] new and unsaved
  #
  def get_journey_pattern(timelit, index, csv_file, csv_file_lineno)
    # We make the name unique with the start time and index
    name = "Route #{route.code} #{direction} #{day_class} S #{self.name}-#{index} #{timelit}"
    JourneyPattern.new(:name            => name,
                       :csv_file        => csv_file,
                       :csv_file_lineno => csv_file_lineno)
  end

  #--------------------------------------------------------------------------------------
  # Finding Services
  #--------------------------------------------------------------------------------------

  DATE_FIELDS = %W(sunday monday tuesday wednesday thursday friday saturday)

  def self.find_by_route_and_date(route, date)
    Service.where(DATE_FIELDS[date.wday] => true,
                  :route_id => route.id,
                  :operating_period_start_date.lte => date.to_mongo,
                  :operating_period_end_date.gte => date.to_mongo).all
  end

  def self.find_by_date(route, date)
    Service.where(DATE_FIELDS[date.wday] => true,
                  :operating_period_start_date.lte => date.to_mongo,
                  :operating_period_end_date.gte => date.to_mongo).all
  end
=begin

  def self.find_by_route_and_date(route, date)
    self.all :conditions =>
                 [ "#{DATE_FIELDS[date.wday]} AND " +
                       "route_id = ? AND " +
                       "? BETWEEN operating_period_start_date AND operating_period_end_date",
                   route,
                   date.to_date]
  end

  def self.find_by_date(date)
    date = date.to_date

    self.all :conditions =>
                 [ "#{DATE_FIELDS[date.wday]} AND " +
                       "? BETWEEN operating_period_start_date AND operating_period_end_date",
                   date]
  end

=end

  def ensure_slug
    self.slug = self.name.to_url()
  end
end
