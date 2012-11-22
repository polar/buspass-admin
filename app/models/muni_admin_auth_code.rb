class MuniAdminAuthCode
  include MongoMapper::EmbeddedDocument
  embedded_in :master

  key :code, Integer, :default => Proc.new { (Random.new.rand * 10000000000000000).to_i }
  key :planner, Boolean
  key :operator, Boolean

  attr_accessible :planner, :operator
end