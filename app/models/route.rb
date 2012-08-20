##
# Route
#  This is the route for the bus.
#
class Route
  include MongoMapper::Document
  include LocationBoxing
  plugin MongoMapper::Plugins::IdentityMap

  belongs_to :network
  belongs_to :master
  belongs_to :municipality

  key :name,          String
  key :code,          String
  key :sort,          Integer, :default => -1
  key :description,   String
  key :display_name,  String
  key :persistentid,  String
  key :version_cache, Integer
  key :slug,           String

  timestamps!

  attr_accessible :name, :code, :sort, :network, :network_id, :description, :display_name, :persistentid, :version_cache,
                  :network, :network_id, :master, :master_id, :municipality, :municipality_id

  #ensure_index(:network)
  ensure_index(:name, :unique => false) # cannot be unique because of the scope, :unique => true)
  ensure_index(:persistentid, :unique => false)

  before_validation :ensure_slug, :ensure_sort

  validates_presence_of :name
  validates_uniqueness_of :name, :scope => [:master_id, :municipality_id, :network_id]
  validates_presence_of :code
  validates_uniqueness_of :code, :scope => [:master_id, :municipality_id, :network_id]
  validates_presence_of :slug
  validates_uniqueness_of :slug, :scope => [:master_id, :municipality_id, :network_id]

  def ensure_sort
    if (self.sort < 0)
      self.sort = self.code.to_i
    end
  end

  #
  # Route has many JourneyPatterns by way of its Services.
  # The Service will destroy the JourneyPatterns.
  #
  #many :journey_patterns, :order => :name

  def journey_patterns
    (services.map {|s| s.journey_patterns}).reduce([]) {|v,x| v + x}
  end

  def vehicle_journey_count
    (services.map {|s| s.vehicle_journeys.count}).reduce(0) {|v,x| v + x}

  end

  # Services are created for a particular route only
  many :services, :dependent => :destroy, :autosave => false

  def copy!(network)
    ret = Route.new(self.attributes)

    ret.network      = network
    ret.master       = network.master
    ret.municipality = network.municipality

    ret.save!(:safe => true)
    ret
  end

  # A version of a route depends on the modification of its
  # Journey Patterns. If we modified a single journey pattern
  # we've got a new version of the route. The version is
  # the time of the newest journey pattern.
  after_validation :assign_version_cache

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

  def self.definitely_get_route(network, route_code)
    #puts "Route query"
    r = Route.first(:network_id => network.id, :code => route_code)
    #puts r ? "Route found" : "creating...."
    if r.nil?
      r = Route.new(:network => network,
                    :code => route_code,
                    :sort => route_code.to_i,
                    :name => "Route #{route_code}",
                    :master => network.master,
                    :municipality => network.municipality)

      r.persistentid = r.name.hash.abs
      #puts "Route saving...."
      r.save!(:safe => true)
      return r
    end

    #puts "Done."
    return r
  end

  SLUG_TRIES = 10

  def ensure_slug
    if self.slug == nil
      self.slug = self.name.to_url()
      tries     = 0
      while tries < SLUG_TRIES && Municipality.find(:slug => self.slug) != nil
        self.slug = name.to_url() + "-" + (Random.rand*1000).floor
      end
      if tries == SLUG_TRIES
        self.slug = self.id.to_s
      end
    end
    return true
  end
end
