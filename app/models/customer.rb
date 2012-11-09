class Customer
  include MongoMapper::Document
  plugin MongoMapper::Plugins::IdentityMap

  #tango_user

  ROLE_SYMBOLS = [:admin, :super]

  key :name, String
  key :email, String

  many :authentications, :dependent => :destroy

  many :masters, :foreign_key => :owner_id

  attr_accessible :name, :email

  validates :email, :presence => true, :email => true
  def self.search(search)
    if search
      words  = search.split(" ")
      search = "("+words.join(")|(")+")"
      where(:name => /#{search}/)
    else
      where()
    end
  end

  # Some how devise picks up the master_id and thinks its an "enforce"d authentication key.
  # That should be the case for muni_admin, or user, but not admin.
  def self.authentication_keys
    return [:email]
  end

  def authentications_copy(attributes)
    as = []
    for a in self.authentications do
      as << a.copy!(attributes)
    end
    as
  end

  key :role_symbols, Array, :default => []
  attr_accessible :role_symbols

  def add_roles(roles)
    if !roles.is_a? Array
      roles = [roles]
    end
    rs           = (self.role_symbols + roles.map { |x| x.to_s }).uniq
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
    rs = (self.role_symbols) - roles
    self.role_symbols = rs
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

end

