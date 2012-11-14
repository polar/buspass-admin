
# This adds to the Cms::File in ComfortableMexicanSofa

class Cms::File <
    "Cms::Orm::#{ComfortableMexicanSofa.config.backend.to_s.classify}::File".constantize

  key :protected, Boolean, :default => false

  key :persistentid, String, :allow_nil => false

  before_create :assign_persistentid

  def assign_persistentid
    self.persistentid = id.to_s if persistentid.nil?
  end

  attr_accessible :protected, :persistentid

  def is_protected?
    self.protected
  end

  def master
    site.master
  end

  def master_id
    site.master.id
  end
end