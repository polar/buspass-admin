class GoogleUriViewPath
  include MongoMapper::Document

  require "open-uri"
  require "hpricot"
  require "faster_csv"

  key :uri, String

  key :view_path_coordinates, Hash

  attr_accessible :uri, :view_path_coordinates

  timestamps!

  def self.find_or_create(uri)
    GoogleUriViewPath.find_by_uri(uri) ||  GoogleUriViewPath.new(:uri => uri)
  end

  def self.getViewPathCoordinates(uri)
    if uri.start_with?("http:")
      cache = GoogleUriViewPath.find_or_create(uri)
      if cache.view_path_coordinates == nil
        doc = open("#{uri}&output=kml") {|f| Hpricot(f) }
        x = doc.at("geometrycollection/linestring/coordinates").inner_html.split(",0.000000 ").map {|x| eval "[#{x}]" }
        ans = { "LonLat" => x }
        cache.view_path_coordinates = ans
        cache.save!
      else
        ans = cache.view_path_coordinates
      end
      #     puts "URI = #{ans.inspect}"
      return ans
    else
      # KML
      doc = Hpricot(uri)
      x = doc.at("placemark/linestring/coordinates").inner_html.strip.split(",0 ").map {|x| eval "[#{x}].take(2)" }
      ans = { "LonLat" => x }
    end
  end

  def self.read(file)
    ts = []
    FasterCSV.read(file, :headers => true).each do |opts|
      t = GoogleUriViewPath.find_or_create(opts["uri"])
      puts "Found #{GoogleUriViewPath.class_name} at #{t.id} #{t.uri}"
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