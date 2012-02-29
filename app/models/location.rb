class Location
  include MongoMapper::EmbeddedDocument

  key :coordinates, Hash
end
