class Authentication
  include MongoMapper::Document
  plugin MongoMapper::Plugins::IdentityMap

  key :provider
  key :uid
  key :name
  key :original_info, Hash
  key :last_info, Hash

  belongs_to :master
  belongs_to :customer
  belongs_to :muni_admin
  belongs_to :user

  attr_accessible :master, :master_id, :customer, :customer_id, :muni_admin, :muni_admin_id, :user, :user_id

  validates :customer_id, :allow_nil => true, :uniqueness => {:scope => [:provider, :uid], :allow_nil => true}
  validates :muni_admin_id, :allow_nil => true, :uniqueness => {:scope => [:provider, :uid, :master_id], :allow_nil => true}
  validates :user_id, :allow_nil=> true, :uniqueness => {:scope => [:provider, :uid, :master_id], :allow_nil => true}

  def self.create_with_omniauth(auth)
    Authentication.new.tap do |tpauth|
      tpauth.provider      = auth["provider"]
      tpauth.uid           = auth["uid"]
      tpauth.name          = auth["info"]["name"]
      tpauth.original_info = auth["info"]
      tpauth.last_info     = auth["info"]
      tpauth.save!
    end
  end

  def copy!(attributes = { })
    Authentication.new(attributes).tap do |tpauth|
      tpauth.provider      = provider
      tpauth.uid           = uid
      tpauth.name          = name
      tpauth.original_info = original_info
      tpauth.last_info     = last_info
      tpauth.save!
    end
  end

end