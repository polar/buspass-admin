class Cms::Page <
    "Cms::Orm::#{ComfortableMexicanSofa.config.backend.to_s.classify}::Page".constantize

  # Context for pages
  belongs_to :master
  belongs_to :municipality
  belongs_to :network

  attr_accessible :master, :master_id
  attr_accessible :municipality, :municipality_id
  attr_accessible :network, :network_id
end
