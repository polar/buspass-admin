class MuniAdmin
    include MongoMapper::Document
    plugin MongoMapper::Plugins::IdentityMap

    key :provider, String
    key :uid, String

    key :name, String

    many :deployments, :foreign_key => :owner_id

    validates_presence_of :name

    def self.create_with_omniauth(auth)
      create! do |cust|
        cust.provider = auth["provider"]
        cust.uid      = auth["uid"]
        cust.name     = auth["info"]["name"]
      end
    end

    many :deployments, :foreign_key => "owner_id"

    ROLE_SYMBOLS = [:operator, :planner, :super ]

    key :role_symbols, Array, :default => []

    def self.search(search)
      if search
        words = search.split(" ")
        search = "("+words.join(")|(")+")"
        where(:name => /#{search}/)
      else
        where()
      end
    end

    def possible_roles
      return ["operator", "super", "planner"]
    end

    # TODO: Important. The last role in the list is the only significant one.
    def add_roles(roles)
        if !roles.is_a? Array
            roles = [roles]
        end
        rs = (self.role_symbols + roles.map {|x| x.to_s}).uniq
        self.role_symbols = rs
    end

    def add_roles!(roles)
        add_roles(roles)
        save!
    end

    def remove_roles(roles)
        if !roles.is_a? Array
            roles = [roles]
        end
        rs = (self.role_symbols) - (roles.map {|x| x.to_s})
    end

    def remove_roles!(roles)
        remove_roles(roles)
        save!
    end

    # This needs an optional argument. Who knew?
    def roles_list(role = nil)
        self.role_symbols
    end

    def has_role?(role)
        self.role_symbols.include?(role.to_s)
    end

    ##
    # This method allows us to programmatically disable empty password validation
    # by making the @password instance variable non-empty.
    #
    # Purpose:
    # We cannot skip this check on new records without rewriting password_required?. Even
    # so, we would have to build a method to handle the check. We can skip the validate_presence_of
    # check on :password just by assigning the @password instance variable to something that is not empty.
    # We cannot subvert this check by using password= because that alters the encrypted_password, and we want
    # to be able to assign a new user without having to go through the password process.
    #
    #noinspection RubyInstanceMethodNamingConvention
    def disable_empty_password_validation()
        @password = "non-empty"
    end
end