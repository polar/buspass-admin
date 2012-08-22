class ThirdPartyAuth
  include MongoMapper::Document
  plugin MongoMapper::Plugins::IdentityMap

  key :provider
  key :uid
  key :name

  belongs_to :customer
  belongs_to :muni_admin
  belongs_to :user
  belongs_to :admin

  def self.create_with_omniauth(auth)
    self.new.tap do |tpauth|
      tpauth.provider = auth["provider"]
      tpauth.uid      = auth["uid"]
      tpauth.name     = auth["info"]["name"]
      tpauth.save!
    end
  end

end