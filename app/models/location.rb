class Location
  include MongoMapper::EmbeddedDocument

  key :name
  key :coordinates, Hash

  attr_accessible :name, :coordinates

  def same?(location)
    coordinates == location.coordinates && name == location.name
  end
end
