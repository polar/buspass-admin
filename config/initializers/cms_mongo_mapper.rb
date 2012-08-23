
#
# This specifies the MongoMapper backend that I worked so hard on, when
# I should have just implemented the CMS on my own. There is so much Rails
# "magic" in that code, it really needs to go away.
#
# TODO: Really implement a good CMS for this site.
#
require File.expand_path("comfortable_mexican_sofa", File.dirname(__FILE__))
require File.expand_path("mongo_mapper", File.dirname(__FILE__))

if ComfortableMexicanSofa.config.backend.to_s == "mongo_mapper"
  require "mongo_mapper"
  require "comfortable_mexican_sofa/backend/mongo_mapper"
end