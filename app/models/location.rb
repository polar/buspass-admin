class Location
  include MongoMapper::EmbeddedDocument
  include LocationBoxing

  key :name
  key :coordinates, Hash

  attr_accessible :name, :coordinates

  def same?(location)
    location &&
        self.name == location.name &&
        equalCoordinates?(self.coordinates["LonLat"],location.coordinates["LonLat"])
  end
end
