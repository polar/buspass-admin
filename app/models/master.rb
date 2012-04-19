class Master
  include MongoMapper::Document

  # Problem with the "sweetloader"?
  # The submodule Scope will not "autoload", we force it by including it here.
  #include CanTango:Model
  include CanTango::Model::Scope

  key :name, String, :required => true
  key :location, Array
  key :hosturl, String
  key :owner, Admin
  key :muni_owner, MuniAdmin
  key :dbname, String #, :unique => true, :allow_nil => true
  key :slug, String

  attr_accessible :name, :slug, :location, :owner, :dbname, :hosturl, :email, :muni_owner

  before_validation :ensure_slug, :ensure_lonlat

  many :municipalities, :autosave => false

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