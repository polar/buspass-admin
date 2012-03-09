#
# A municipality has a name and a location center.
#
class Municipality
    include MongoMapper::Document

    # Problem with the "sweetloader"?
    # The submodule Scope will not "autoload", we force it by including it here.
    #include CanTango:Model
    include CanTango::Model::Scope

    key :display_name, String, :required => true
    key :name, String
    key :mode, String
    key :status, String
    key :slug, String, :required => true, :unique => true
    key :location, Array
    key :hosturl, String
    key :owner, MuniAdmin

    # The database we are stored in. Self referentcial
    key :dbname, String

    # The database we need to look up the master_municipality in.
    key :masterdb, String
    belongs_to :master_municipality

    attr_accessible :display_name, :slug, :location, :hosturl, :name

    before_validation :ensure_slug, :ensure_lonlat
    many :networks, :autosave => false

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