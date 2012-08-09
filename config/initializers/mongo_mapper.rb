require 'uri'
require 'mongo'

if ENV['MONGOLAB_URI']
  uri  = URI.parse(ENV['MONGOLAB_URI'])
  MongoMapper.connection = conn = Mongo::Connection.from_uri(ENV['MONGOLAB_URI'])
  db = conn.db(uri.path.gsub(/^\//, '')) 
else
  MongoMapper.connection = Mongo::Connection.new('localhost', 27017, :logger => Rails.logger)
  MongoMapper.database = "#Busme-#{Rails.env}"
end


if defined?(PhusionPassenger)
   PhusionPassenger.on_event(:starting_worker_process) do |forked|
     MongoMapper.connection.connect if forked
   end
end
