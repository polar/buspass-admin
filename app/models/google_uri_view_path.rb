class GoogleUriViewPath
  include MongoMapper::Document

  require "open-uri"
  require "hpricot"
  require "faster_csv"

  key :uri, String, :unique => true

  ensure_index :uri, :unique => true

  key :view_path_coordinates, Hash, :default => nil

  attr_accessible :uri, :view_path_coordinates

  timestamps!

  def self.create_indexes
    self.ensure_index(:uri, :unique => true)
  end

  def self.find_or_create(uri)
    GoogleUriViewPath.find_by_uri(uri) ||  GoogleUriViewPath.new(:uri => uri)
  end

  def self.getViewPathCoordinates(uri)
    #puts ("looking for #{uri}")
    ans = nil
    if uri.start_with?("http:")
      cache = GoogleUriViewPath.find_or_create(uri)
      if cache.view_path_coordinates == nil || cache.view_path_coordinates == {}
        #puts "no cache item, getting from Internet"
        doc = open(uri) {|f| Hpricot(f) }
        if doc
          coord_html = doc.at("geometrycollection/linestring/coordinates")
          if coord_html
             x = coord_html.inner_html.split(",0.000000 ").map {|x| eval "[#{x}]" }
             ans = { "LonLat" => x }
             cache.view_path_coordinates = ans
             cache.save!
          end
        end
      else
        ans = cache.view_path_coordinates
      end
    else
      # KML
      doc = Hpricot(uri)
      if doc
        coord_html = doc.at("placemark/linestring/coordinates")
        if coord_html
          x = coord_html.inner_html.strip.split(",0 ").map {|x| eval "[#{x}].take(2)" }
          ans = { "LonLat" => x }
        end
      end
    end
    return ans
  end

  def self.read(file)
    ts = []
    FasterCSV.read(file, :headers => true).each do |opts|
      t = GoogleUriViewPath.find_or_create(opts["uri"])
      #puts "Found #{GoogleUriViewPath.class_name} at #{t.id} #{t.uri}"
      t.uri = opts["uri"]
      s =  YAML::load(opts["coordinates"])
      if (s.is_a? Hash)
        t.view_path_coordinates = s
      elsif (s.is_a? String)
        t.view_path_coordinates = YAML::load(s)
      else
        raise "Invalid Format for Coordinates"
      end

      ts << t
      t.save!
    end
    ts
  end

  HEADER = ["uri", "coordinates"]
  def self.to_csv(ts = nil)
    if (ts == nil)
      ts = GoogleUriViewPath.all
    end
    if (ts.empty?)
      FasterCSV::Table.new(
          [FasterCSV::Row.new(HEADER,
                              ["",""])])
    else
      FasterCSV::Table.new(ts.collect { |x| x.to_csv})
    end
  end

  def self.write(name)
    csv = FasterCSV.open(name, "w+")
    csv << FasterCSV::Row.new(HEADER,HEADER)
    GoogleUriViewPath.all.each {|x| csv << x.to_csv }
    csv.close
  end

  def to_csv
    FasterCSV::Row.new(HEADER,
                       [uri, view_path_coordinates.to_yaml.to_s.inspect]);
  end
end
