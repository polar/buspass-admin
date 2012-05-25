
# This adds to the Cms::Site in ComfortableMexicanSofa

class Cms::Site <
    "Cms::Orm::#{ComfortableMexicanSofa.config.backend.to_s.classify}::Site".constantize

  belongs_to :master, :class_name => "Master"

  attr_accessible :master, :master_id

end