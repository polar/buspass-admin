class Master
  include MongoMapper::Document

  # Problem with the "sweetloader"?
  # The submodule Scope will not "autoload", we force it by including it here.
  #include CanTango:Model
  include CanTango::Model::Scope

  key :name, String, :required => true
  key :location, Array
  key :host, String
  key :hosturl, String
  key :muni_owner, MuniAdmin
  key :dbname, String #, :unique => true, :allow_nil => true
  key :slug, String

  attr_accessible :name, :slug, :location, :owner, :dbname, :hosturl, :email, :muni_owner

  before_validation :ensure_slug, :ensure_lonlat

  belongs_to :owner, :class_name => "Customer"

  many :municipalities, :autosave => false, :dependent => :destroy
  one :deployment, :dependent => :destroy
  one :testament, :dependent => :destroy

  def self.owned_by(customer)
    where(:owner_id => customer.id)
  end

  # CMS Integration
  # Arrg! MongoMappe requires that this be a many association because of the "belongs_to" in site.
  many :sites, :class_name => "Cms::Site", :dependent => :destroy
  def admin_site
    sites.find_by_identifier("#{slug}-admin")
  end
  def main_site
    sites.find_by_identifier("#{slug}-main")
  end
  def admin_site=(site)
    sites << site
  end
  def main_site=(site)
    sites << site
  end
  #one :admin_site, :class_name => "Cms::Site", :dependent => :destroy
  #one :main_site, :class_name => "Cms::Site", :dependent => :destroy

  # TODO: TimeZones by location.   http://earthtools.org
  TIME_ZONE = "America/New_York"
  TZ = Time.now.in_time_zone(TIME_ZONE).zone

  def time_zone
    return TIME_ZONE
  end

  def tz(time)
    time.in_time_zone(TIME_ZONE)
  end

  def ensure_lonlat
    if self.location != nil
      if self.location.is_a? String
        self.location = self.location.split(",")
      end
      if self.location.is_a? Array
        self.location = self.location.map { |x| x.to_f }
      end
      if self.location.length != 2
        self.errors.add("location", "needs two elements")
        return
      end
      if self.location[0] < -180 || 180 < self.location[0]
        self.errors.add("location", "longitude value error")
      end
      if self.location[1] < -90 || 90 < self.location[1]
        self.errors.add("location", "latitude value error")
      end
    end
  end


  SLUG_TRIES = 10

  def ensure_slug
    if self.slug == nil
      self.slug = self.name.to_url()
      tries     = 0
      while tries < SLUG_TRIES && Master.find(:slug => self.slug) != nil
        self.slug = name.to_url() + "-" + (Random.rand*1000).floor
      end
      if tries == SLUG_TRIES
        self.slug = self.id.to_s
      end
    end
    return true
  end
end