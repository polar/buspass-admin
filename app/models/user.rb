class User
  include MongoMapper::Document
  plugin MongoMapper::Plugins::IdentityMap


  key :provider, String
  key :uid, String

  key :name, String
  key :email, String

  belongs_to :master
  many :authentications, :dependent => :destroy

  validates_presence_of :name
  validates :email, :presence => true, :email => true

  def self.create_with_omniauth(auth)
    create! do |cust|
      cust.provider = auth["provider"]
      cust.uid      = auth["uid"]
      cust.name     = auth["info"]["name"]
    end
  end

  # Array of String
  key :role_symbols, Array, :default => []

  validates_presence_of :name

  ROLE_SYMBOLS =  ["customer", "driver"]

  def possible_roles
    return ROLE_SYMBOLS
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

  def self.search(search)
    if search
      # TODO: Security Risk? Words may contain characters? Need escape?
      words = search.split(" ")
      search = "("+words.join(")|(")+")"
      regexp = /#{search}/
      where(:name => regexp)
    else
      where()
    end
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