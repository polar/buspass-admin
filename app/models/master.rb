class Master
  include MongoMapper::Document

  # Problem with the "sweetloader"?
  # The submodule Scope will not "autoload", we force it by including it here.
  #include CanTango:Model
  include CanTango::Model::Scope

  key :name, String, :required => true
  key :longitude
  key :latitude
  key :slug, String
  key :timezone, String

  # This will be used if we shard the Master off to its own Database.
  key :dbname, String #, :unique => true, :allow_nil => true

  belongs_to :owner, :class_name => "Customer"
  many :municipalities, :autosave => false, :dependent => :destroy
  one :activement, :dependent => :destroy
  one :testament, :dependent => :destroy

  attr_accessible :name, :slug, :owner, :dbname
  attr_accessible :longitude, :latitude, :timezone

  before_validation :ensure_slug

  validates_uniqueness_of :name
  validates_uniqueness_of :slug
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
  def admin_site=(site)
    sites << site
  end
  def main_site=(site)
    sites << site
  end

  def hosturl
    "http://#{self.slug}.busme.us/"
  end

  def siteurl
    "http://busme.us/#{self.slug}."
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

  def ensure_slug
    self.slug = self.name.to_url()
  end
end