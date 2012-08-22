class Customer
  include MongoMapper::Document
  plugin MongoMapper::Plugins::IdentityMap

  tango_user

  ROLE_SYMBOLS = [:admin, :super]

  key :name, String
  key :email, String

  many :third_party_auths

  many :masters, :foreign_key => :owner_id

  attr_accessible :name, :email

  validates :email, :presence => true, :email => true

  def self.create_with_omniauth(auth, session)
    Customer.new.tap do |cust|
      cust.provider = auth["provider"]
      cust.uid      = auth["uid"]
      cust.name     = auth["info"]["name"]
      cust.save!
    end
  end

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

  key :role_symbols, Array, :default => []
  attr_accessible :role_symbols

  def add_roles(roles)
    if !roles.is_a? Array
      roles = [roles]
    end
    rs           = (role_symbols + roles).uniq
    role_symbols = rs
  end

  def add_roles!(roles)
    add_roles(roles)
    save!
  end

  def remove_roles(roles)
    if !roles.is_a? Array
      roles = [roles]
    end
    rs = (role_symbols) - roles
  end

  def remove_roles!(roles)
    remove_roles(roles)
    save!
  end

  def roles_list
    role_symbols
  end

  def has_role?(role)
    roles_list.include?(role.to_s)
  end
end

