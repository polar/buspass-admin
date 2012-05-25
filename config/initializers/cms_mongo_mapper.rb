
require File.expand_path("comfortable_mexican_sofa", File.dirname(__FILE__))
require File.expand_path("mongo_mapper", File.dirname(__FILE__))

if ComfortableMexicanSofa.config.backend.to_s == "mongo_mapper"
  require "mongo_mapper"
  require "comfortable_mexican_sofa/backend/mongo_mapper"
end