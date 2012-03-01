class Location
  include MongoMapper::EmbeddedDocument

  key :name
  key :coordinates, Hash

  attr_accessible :name, :coordinates
end
