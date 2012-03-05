##
# Route
#  This is the route for the bus.
#
class Route
  include MongoMapper::Document
  include LocationBoxing

  belongs_to :network

  key :name, String
  key :code, String
  key :description, String
  key :display_name, String
  key :persistentid, String
  key :version_cache, Integer

  timestamps!

  attr_accessible :name, :code, :network, :description,:display_name, :persistentid

  #ensure_index(:network)
  ensure_index(:name) # cannot be unique because of the scope, :unique => true)

  #
  # Route has many JourneyPatterns by way of its Services.
  # The Service will destroy the JourneyPatterns.
  #
  #many :journey_patterns, :order => :name

  def journey_patterns
    (services.map {|s| s.journey_patterns}).reduce([]) {|v,x| v + x}
  end

  # Services are created for a particular route only
  many :services, :dependent => :destroy, :autosave => false

  before_validation :bv

  def bv
    #puts "Route. validating..."
    @valid_start = Time.now
  end
  def av
    #puts "Route. Done. validation #{Time.now - @valid_start}"
  end

  def bs
    #puts "Route before save"
    @save_start = Time.now
  end
  def asave
    #puts "Route after save #{Time.now - @save_start}"
  end
  before_save :bs
  after_save :asave

  # The Route's persistenid is its code
  validates_uniqueness_of :name, :scope => :network_id
  validates_uniqueness_of :code, :scope => :network_id

  # A version of a route depends on the modification of its
  # Journey Patterns. If we modified a single journey pattern
  # we've got a new version of the route. The version is
  # the time of the newest journey pattern.
  after_validation :assign_version_cache, :av

  def version
    if (version_cache)
      return version_cache
    else
      return get_version
    end
  end

  def get_version
    datei = updated_at.to_i
    for jp in journey_patterns do
      datei = datei > jp.version ? datei : jp.version
    end
    return datei
  end

  def assign_version_cache
    self.version_cache = get_version()
  end

  # Returns the location bounding box
  def theBox
    if (journey_patterns.size == 0)
      return [[0.0,0.0],[0.0,0.0]]
    end
    return journey_patterns.reduce(journey_patterns.first.theBox) {|v,jp| combineBoxes(v,jp.theBox)}
  end

  def locatedBy(location)
    journey_patterns.reduce(false) {|v,tl| v || tl.locatedBy(location) }
  end

  def isOnRoute(location,buffer)
    journey_patterns.reduce(false) {|v,tl| v || tl.isOnRoute(location, buffer) }
  end

  def self.find_by_location(location)
    self.all.select {|r| r.locatedBy(location)}
  end

  def self.find_or_create_by_number(network, route_number)
    #puts "Route query"
    r = Route.first(:network_id => network.id, :code => route_number)
    #puts r ? "Route found" : "creating...."
    r ||= Route.new(:network => network, :code => route_number, :name => "Route #{route_number}")

    r.persistentid = r.name.hash.abs
    #puts "Route saving...."
    r.save!
    #puts "Done."
    return r
  end

end
