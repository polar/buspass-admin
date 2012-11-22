class Master
  include MongoMapper::Document
  plugin MongoMapper::Plugins::IdentityMap

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

  # This will be used if we shard the Master off to its own Database.
  key :dbname, String #, :unique => true, :allow_nil => true

  belongs_to :owner, :class_name => "Customer"
  many :deployments, :autosave => false, :dependent => :destroy
  one :activement, :dependent => :destroy
  one :testament, :dependent => :destroy

  # embedded
  many :muni_admin_auth_codes, :autosave => false do
    def destroy(auth_code)
      if auth_code.is_a? MuniAdminAuthCode
        proxy_owner.pull(:muni_admin_auth_codes => { :_id => auth_code.id })
      else
        proxy_owner.pull(:muni_admin_auth_codes => { :_id => auth_code })
      end
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

  def ensure_slug
    self.slug = self.name.to_url() if !self.slug
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