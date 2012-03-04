##
# Service
#   This class represents the Service Parameters for a particular Route.
#
class Service
  include MongoMapper::Document

  belongs_to :route
  belongs_to :network

  key :name,         String, :unique => true
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

  timestamps!

  def self.create_indexes
    self.ensure_index(:network_id)
    self.ensure_index(:route_id)
    self.ensure_index(:name, :unique => true)
  end

  attr_accessible :name, :route, :operating_period_end_date, :operating_period_start_date, :direction, :day_class,
                  :network_id, :route_id

  before_validation :day_class_sync

  def day_class_sync
    self.setOperatingDays(day_class)
  end

  #
  # Currently, journey patterns are not shared, and neither
  # are their timing links.
  #
  #many :journey_patterns, :dependent => :destroy
  many :vehicle_journeys, :dependent => :destroy

  def journey_patterns
    vehicle_journeys.map {|s| s.journey_pattern}
  end

  def network
    route.network
  end

  #
  # The constructed name of a service is unique so it can be a persistent id
  # as well. That means we can update it from a CSV file.  Example:
  #  Route {code} {Weekday|Daily|Saturday|Sunday|Weekend} {Inbound|Outbound} Service <StartDate> to <EndDate>
  # For consistency the id is the hash of the name
  #
  validates_uniqueness_of :name, :scope => :network

  def self.find_or_create_by_route(network, route_number, direction, designator, start_date, end_date)
    sd = start_date.strftime("%Y-%m-%d")
    ed = end_date.strftime("%Y-%m-%d")
    name = "Route #{route_number} #{designator} Service #{direction} #{sd} to #{ed}"
    s = Service.first(:network_id => network.id, :name => name)
    s ||= Service.new(:network_id => network.id, :name => name)
    s.operating_period_start_date = start_date
    s.operating_period_end_date = end_date
    s.setOperatingDays(designator)
    s.direction = direction
    s.route = Route.first(:network_id => network.id, :code => route_number)
    s.save!
    return s
  end

  def locatedBy(location)
    journey_patterns.reduce(false) {|v,tl| v || tl.locatedBy(coord) }
  end

  def setOperatingDays(designator)
    self.day_class= designator

    self.monday = false
    self.tuesday = false
    self.wednesday = false
    self.thursday = false
    self.friday = false
    self.saturday = false
    self.sunday = false

    case designator
      when "Weekday"
        self.monday = true
        self.tuesday = true
        self.wednesday = true
        self.thursday = true
        self.friday = true
      when "Daily"
        self.monday = true
        self.tuesday = true
        self.wednesday = true
        self.thursday = true
        self.friday = true
        self.saturday = true
        self.sunday = true
      when "Saturday"
        self.saturday = true
      when "Sunday"
        self.sunday = true
      when "Weekend"
        self.saturday = true
        self.sunday = true
      when "Friday"
        self.friday = true
      when "Mon-Thurs"
        self.monday = true
        self.tuesday = true
        self.wednesday = true
        self.thursday = true
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
  def get_journey_pattern(time, index, csv_file, csv_file_lineno)
    # We make the name unique with the start time and index
    name = "Route #{route.code} #{direction} #{day_class} S #{self.name}-#{index} #{time.strftime("%H:%M")}"
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
end
