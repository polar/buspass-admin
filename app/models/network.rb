require "carrierwave/orm/mongomapper"

class Network
  include MongoMapper::Document
  include LocationBoxing
  plugin MongoMapper::Plugins::IdentityMap

  key :name,        String
  key :description, String
  key :mode,        String # :planning, :testing, :retired, :actives
  key :file_path,   String
  key :slug,        String

  timestamps!

  key :processing_lock,     MuniAdmin, :default => nil
  key :processing_token,    String
  key :processing_progress, Float, :default => 0.0
  key :processing_errors,   Array
  key :processing_log,      Array

  belongs_to :processing_job, :class_name => "Delayed::Job"

  key :processing_started_at,   Time
  key :processing_completed_at, Time

  belongs_to :copy_lock, :class_name => "Network"

  key :copy_progress, Float, :default => 0.0
  key :copy_errors,   Array
  key :copy_log,      Array

  belongs_to :copy_job, :classs_name => "Delayed::Job"

  key :copy_started_at,   Time
  key :copy_completed_at, Time

  belongs_to  :deployment
  belongs_to  :master

  # We need :autosave off for copy!
  many :routes, :dependent => :destroy, :autosave => false
  many :services, :dependent => :destroy, :autosave => false
  many :vehicle_journeys, :dependent => false, :autosave => false

  many :active_copies, :class_name => "Network", :foreign_key => :copy_lock_id

  # CMS Integration
  one :site, :class_name => "Cms::Site"
  one :page, :class_name => "Cms::Page", :dependent => :destroy

  # This field is where the zipfile gets uploaded. We need to
  # move it to a more permanent place..The Controller will
  # move this to file.
  mount_uploader :upload_file, NetworkFileUploader

  ensure_index(:name, :unique => false)
  def self.create_indexes
    self.ensure_index(:name, :unique => false)
  end

  before_validation :ensure_slug

  validates_presence_of :name
  validates_uniqueness_of :name, :scope => [ :master_id, :deployment_id ]
  validates_uniqueness_of :slug, :scope => [ :master_id, :deployment_id ]

  attr_accessible :name, :mode, :description
  attr_accessible :deployment, :deployment_id, :master, :master_id

  def self.create_copy(fromnet, deployment)
    network = Network.new()
    network.deployment = deployment
    network.master = deployment.master
    network.description = fromnet.description
    network.copy_lock = fromnet
    network.name = fromnet.name

    # The only validity concern we have is the uniqueness of the name
    # in the new deployment.
    i = 1
    name = network.name
    while i < 1000 && !network.valid? do
      network.name = "#{name}-#{i}"
      i += 1
    end

    if (i == 1000)
      raise "Could not create network. Too many networks named '#{name}'."
    end

    network.save!(:safe => true)

    return network
  end

  def self.copy_content(fromnet, tonet)
    tonet.copy_started_at = Time.now
    copy_routes = {}
    copy_services = []
    copy_vehicle_journeys = []
    # We base progress on vehicle journeys
    total_journey_count = fromnet.vehicle_journey_count
    copy_journey_count = 0
    begin
      for s in fromnet.services
        tonet.copy_log << "Copying Service #{s.name}"
        if copy_routes[s.route.code] == nil
          copy_routes[s.route.code] = s.route.copy!(tonet)
          tonet.copy_log << "Copying Route #{s.route.name}"
        end
        tonet.save
        route = copy_routes[s.route.code]
        service = s.copy!(route, tonet)
        copy_services << service
        for vj in s.vehicle_journeys
          tonet.copy_log << "Copying Journey #{vj.name}"
          vehicle_journey = vj.copy!(service, tonet)
          copy_journey_count += 1
          tonet.copy_progress = copy_journey_count.to_f / total_journey_count.to_f
          tonet.save
          copy_vehicle_journeys << vehicle_journey
        end
      end
    rescue Exception => boom
      tonet.copy_errors << "#{boom}"
      copy_routes.values.each {|x| x.delete() }
      copy_services.each {|x| x.delete() }
      copy_vehicle_journeys.each {|x| x.delete() }
      tonet.delete
      tonet = nil
      raise "Cannot create network #{boom}"
    ensure
      if tonet
        tonet.copy_lock = nil
        tonet.copy_completed_at = Time.now
        tonet.save
      end
    end
  end
  #
  # Copies the network into the deployment, changing the name if
  # needed.
  #
  def copy!(deployment)
    network = Network.new(self.attributes)
    network.deployment = deployment
    network.master = deployment.master
    # The only validity concern we have is the uniqueness of the name
    # in the new deployment.
    i = 1
    name = network.name
    while i < 1000 && !network.valid? do
      network.name = "#{name}-#{i}"
      i += 1
    end

    if (i == 1000)
      raise "Could not create network. Too many networks named '#{name}'."
    end

    if network.save(:safe => true)
      routes = {}
      services = []
      vehicle_journeys = []
      begin
        for s in self.services
          if routes[s.route.code] == nil
            routes[s.route.code] = s.route.copy!(network)
          end
          route = routes[s.route.code]
          #puts "Copy Service #{s.id} to route #{route.id} and network #{network.id}"
          service = s.copy!(route, network)
          #puts "Cloned to Service #{service.id} "
          services << service
          for vj in s.vehicle_journeys
            vehicle_journey = vj.copy!(service, network)
            vehicle_journeys << vehicle_journey
          end
        end
        network.reload
        network
      rescue  Exception => boom
        routes.values.each {|x| x.delete() }
        services.each {|x| x.delete() }
        vehicle_journeys.each {|x| x.delete() }
        network.delete
        raise "Cannot create network #{boom}"
      end
    else
      raise "Cannot create network #{network.errors.message}"
    end
  end

  def is_locked?
    (processing_lock && processing_job) || copy_lock
  end

  def has_processing_errors?
    !processing_errors.empty?
  end

  def owner
    deployment.owner
  end

  def route_codes
    routes.map {|x| x.code }
  end

  def route_count
    routes.count
  end

  def vehicle_journey_count
    services.map  {|r| r.vehicle_journeys.count }.reduce(0) {|v,x| v + x}
  end

  def service_count
     routes.map {|r| r.services.count }.reduce(0) {|v,x| v + x}
  end

  def inconsistent_journeys
    vehicle_journeys.all.select {|vj| ! vj.check_consistency }
  end

  def service_dates
    dates = services.map {|s| [s.operating_period_start_date, s.operating_period_end_date]}
    dates.reduce {|v,s| [ [v[0],s[0]].min, [v[1],s[0]].max ]}
  end

  def delete_routes
    routes.each { |x| x.destroy }
  end

  def ensure_slug
    self.slug = self.name.to_url()
  end

  def version
    routes.reduce(0) {|t,v| [t,v.version].max}
  end

  # Returns the location bounding box
  def theBox
    journey_patterns = routes.reduce([]) {|t,v| t + v.journey_patterns}
    if (journey_patterns.size == 0)
      return [[0.0,0.0],[0.0,0.0]]
    end
    return journey_patterns.reduce(journey_patterns.first.theBox) {|v,jp| combineBoxes(v,jp.theBox)}
  end
end