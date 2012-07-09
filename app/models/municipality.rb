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
    key :note, String
    key :status, String
    key :slug, String, :required => true #, :unique => { :scope => [:master_id] }
    key :longitude
    key :latitude

    # The database we are stored in. Self referential
    key :dbname, String

    # The database we need to look up the master_municipality in.
    key :masterdb, String

    belongs_to :master
    belongs_to :owner, :class_name => "MuniAdmin"

    one :deployment, :dependent => :delete
    one :testament, :dependent => :delete
    many :networks, :autosave => false, :dependent => :destroy

    # CMS Integration
    one :site, :class_name => "Cms::Site", :dependent => :destroy
    one :page, :class_name => "Cms::Page", :dependent => :destroy

    attr_accessible :display_name, :slug, :name, :note, :status

    before_validation :ensure_slug

    validates_uniqueness_of :name, :scope => [:master_id]
    validates_uniqueness_of :slug, :scope => [:master_id]
    validates_numericality_of :longitude, :greater_than_or_equal_to => -180.0, :less_than_or_equal_to => 180.0
    validates_numericality_of :latitude, :greater_than_or_equal_to => -90.0, :less_than_or_equal_to => 90.0

    def self.owned_by(muni_admin)
      where(:owner_id => muni_admin.id)
    end

    def location
      [ self.longitude, self.latitude ]
    end

    def route_codes
      networks.reduce([]) { |v,n| v + (n.routes.map {|x| x.code})}
    end

    def routes
      networks.reduce([]) { |v,n| v + n.routes }
    end

    def ensure_slug
        self.slug = self.name.to_url()
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