class Master
  include MongoMapper::Document
  plugin MongoMapper::Plugins::IdentityMap
  include LocationBoxing

  # Problem with the "sweetloader"?
  # The submodule Scope will not "autoload", we force it by including it here.
  #include CanTango:Model
  include CanTango::Model::Scope

  key :name, String, :required => true
  key :longitude
  key :latitude
  key :slug, String
  key :timezone, String
  key :max_workers, Integer, :default => 3
  key :date_format, String, :default => "%Y-%m-%d"

  key :base_host, :default => Rails.application.base_host
  key :admin_host
  key :main_host
  key :api_host


  key :nw_lat, Float
  key :nw_lon, Float
  key :se_lat, Float
  key :se_lon, Float
  key :nw_lon_lte_se_lon, Boolean

  # This will be used if we shard the Master off to its own Database.
  key :dbname, String #, :unique => true, :allow_nil => true

  belongs_to :owner, :class_name => "Customer"
  many :deployments, :autosave => false, :dependent => :destroy
  one :activement, :dependent => :destroy
  one :testament, :dependent => :destroy

  many :service_table_jobs
  many :simulate_jobs

  before_validation :set_box

  def set_box
    coords = [self.longitude.to_f, self.latitude.to_f]
    box = getBox(coords, coords)
    box = enlargeBox(box, 50 * FEET_PER_KM) # 50k
    self.nw_lon= box[0][0]
    self.nw_lat= box[0][1]
    self.se_lon= box[1][0]
    self.se_lat= box[1][1]
    # This is for querying in MongoDB, since it's really difficult to compare two fields.
    # we just do that comparison here and store it.
    self.nw_lon_lte_se_lon = self.nw_lon <= self.se_lon
  end

  def self.by_location(lon, lat)
    where(LocationBoxing.getWithinQueryPlucky(lon, lat))
  end

  def locatedBy(coord)
    inBox(theBox, coord)
  end

  def theBox
    [[nw_lon, nw_lat], [se_lon, se_lat]]
  end

  # Store the locator box
  def assign_lon_lat_locator_fields
    self.coordinates_cache = get_geometry()

    if (!journey_pattern_timing_links.empty?)
      box = journey_pattern_timing_links.reduce(journey_pattern_timing_links.first.theBox) { |v, jptl| combineBoxes(v, jptl.theBox) }
      self.nw_lon= box[0][0]
      self.nw_lat= box[0][1]
      self.se_lon= box[1][0]
      self.se_lat= box[1][1]
    else
      self.nw_lon= 0
      self.nw_lat= 0
      self.se_lon= 0
      self.se_lat= 0
    end
  end

  def delayed_job_queue
    self.slug
  end

  def delayed_jobs
    Delayed::Job.where(:queue => self.delayed_job_queue, :failed_at => nil).all
  end

  def delayed_job_count
    Delayed::Job.where(:queue => self.delayed_job_queue, :failed_at => nil).count
  end

  def delayed_job_start_workers
    jcount = delayed_job_count # This count includes this job
    wcount = delayed_job_worker_count
    if jcount > wcount && wcount < max_workers
      Rush::Box.new[Rails.root].bash("script/delayed_job start -i workless-#{self.delayed_job_queue}-#{Time.now.to_i} --queues=#{self.delayed_job_queue} --exit_on_zero", :background => true)
      sleep 1
    end
    true
  end

  def delayed_job_stop_workers
    Rush::Box.new.processes.filter(:cmdline => /delayed_job start -i workless-#{self.delayed_job_queue}|delayed_job.workless-#{self.delayed_job_queue}/).each do |p|
      p.kill
    end

  end

  # TODO Integrate with Delayed::Job
  def delayed_job_worker_count
    # We count the number of matching lines
    Rush::Box.new.processes.filter(:cmdline => /delayed_job start -i workless-#{self.delayed_job_queue}|delayed_job.workless-#{self.delayed_job_queue}/).size
  end

  # embedded
  many :muni_admin_auth_codes, :autosave => false do
    def destroy(auth_code)
      if auth_code.is_a? MuniAdminAuthCode
        proxy_owner.pull(:muni_admin_auth_codes => { :_id => auth_code.id })
      else
        proxy_owner.pull(:muni_admin_auth_codes => { :_id => auth_code })
      end
    end
    def destroy!(auth_code)
      if auth_code.is_a? MuniAdminAuthCode
        proxy_owner.pull(:muni_admin_auth_codes => { :_id => auth_code.id })
      else
        proxy_owner.pull(:muni_admin_auth_codes => { :_id => auth_code })
      end
      proxy_owner.reload
    end
  end

  attr_accessible :name, :slug, :owner, :dbname
  attr_accessible :longitude, :latitude, :timezone

  before_validation :ensure_slug

  validates_uniqueness_of :name
  validates_uniqueness_of :slug
  validates_format_of :slug, :with => /[a-z][a-z0-9-]*/, :message => "only lower case letters, numbers, and dashes"
  validates_length_of :slug, :maximum => 20, :message => "can only be 20 characters long"
  validates_numericality_of :longitude, :greater_than_or_equal_to => -180.0, :less_than_or_equal_to => 180.0
  validates_numericality_of :latitude, :greater_than_or_equal_to => -90.0, :less_than_or_equal_to => 90.0

  def self.owned_by(customer)
    where(:owner_id => customer.id)
  end

  def location
    [ self.longitude, self.latitude ]
  end

  # CMS Integration
  # Arrg! MongoMapper requires that this be a many association because of the "belongs_to" in
  # our extension of Cms::Site.
  #one :admin_site, :class_name => "Cms::Site", :dependent => :destroy
  #one :main_site, :class_name => "Cms::Site", :dependent => :destroy
  many :sites, :class_name => "Cms::Site", :dependent => :destroy

  def admin_site
    sites.find_by_identifier(/-admin/)
  end

  def main_site
    sites.find_by_identifier(/-main/)
  end

  def error_site
    sites.find_by_identifier(/-error/)
  end

  def admin_site=(site)
    sites << site
  end

  def main_site=(site)
    sites << site
  end

  def error_site=(site)
    sites << site
  end

  # TODO: ssl
  def hosturl
    "http://#{self.slug}.#{BuspassAdmin::Application.base_host}/"
  end

  # TODO: ssl
  def siteurl
    "http://#{BuspassAdmin::Application.base_host}/#{self.slug}."
  end

  # TODO: TimeZones by location.   http://earthtools.org
  TIME_ZONE = "America/New_York"
  TZ = Time.now.in_time_zone(TIME_ZONE).zone

  def time_zone
    return timezone
  end

  def tz(time)
    time.in_time_zone(time_zone)
  end

  def base_time(reference = Time.now)
    timelit = tz(reference).strftime("%Y-%m-%d 0:00 %z")
    return Time.parse(timelit)
  end

  def ensure_slug
    self.slug       ||= self.name.to_url()
    self.base_host  ||= Rails.application.base_host
    self.admin_host ||= "#{self.slug}.#{self.base_host}"
    self.main_host  ||= "#{self.slug}.#{self.base_host}"
    self.api_host   ||= "#{self.slug}.#{self.base_host}"
  end

  def assign_base_host(bhost)
    self.base_host  = bhost
    self.admin_host = "#{self.slug}.#{self.base_host}"
    self.main_host  = "#{self.slug}.#{self.base_host}"
    self.api_host   = "#{self.slug}.#{self.base_host}"
  end

  before_destroy :destroy_related
  def destroy_related
    # It should destroy the sites. We will get rid of all the accounts associated with the Master as well.
    MuniAdmin.where(:master_id => self.id).all.each { |m| m.destroy }
    User.where(:master_id => self.id).all.each { |m| m.destroy }
    # We will get rid of the customer if this was his only master and the customer isn't a Busme Administrator.
    if self.owner && self.owner.masters.count == 1 && ! self.owner.has_role?(:super)
      self.owner.destroy
    end
  end
end