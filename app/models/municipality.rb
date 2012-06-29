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
    key :slug, String, :required => true #, :unique => { :scope => [:master_id] }
    key :location, Array
    key :hosturl, String
    belongs_to :owner, :class_name => "MuniAdmin"

    # The database we are stored in. Self referential
    key :dbname, String

    # The database we need to look up the master_municipality in.
    key :masterdb, String
    belongs_to :master

    attr_accessible :display_name, :slug, :location, :hosturl, :name, :mode

    before_validation :ensure_slug, :ensure_lonlat
    validates_uniqueness_of :slug, :scope => [:master_id]
    many :networks, :autosave => false, :dependent => :destroy

    one :deployment
    one :testament

    one :site, :class_name => "Cms::Site", :dependent => :destroy
    one :page, :class_name => "Cms::Page", :dependent => :destroy

    def route_codes
      networks.reduce([]) { |v,n| v + (n.routes.map {|x| x.code})}
    end

    def routes
      networks.reduce([]) { |v,n| v + n.routes }
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
            while tries < SLUG_TRIES && Municipality.where(:master_id => master.id, :slug => self.slug).first != nil
                self.slug = name.to_url() + "-" + (Random.rand*1000).floor
            end
            if tries == SLUG_TRIES
                self.slug = self.id.to_s
            end
        end
        return true
    end

    #
    # A Municipality can only be deployed if its networks do not
    # have any overlapping route codes. If this municipality can be deployed,
    # it returns  an empty array of strings. Otherwise, it contains a list of strings
    # denoting the errors encountered.
    #
    def deployment_check
      status = []
      route_codes = []
      for n in networks do
        route_codes += n.route_codes
        if n.has_errors?
          status << "Network ''#{n.name}'' has errors."
        end
      end
      dups = route_codes.inject({}) {|h,v| h[v]=h[v].to_i+1; h}.reject{|k,v| v==1}.keys
      if ! dups.empty?
        status << "Networks within a plan must not have common routes."
        status << "Some networks in this plan share these route codes: #{dups.join(', ')}."
      end
      return status
    end

end