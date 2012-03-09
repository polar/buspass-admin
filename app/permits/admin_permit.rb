class AdminPermit < CanTango::UserPermit
  def initialize(ability)
    super
  end

  protected

  def dynamic_rules
    can([:edit, :delete], Master) do |muni|
      muni.owner === user
    end
  end

  def permit_rules
    can(:create, Master)
    can(:read, Master)
    can(:create, Municipality)
    can(:read, Municipality)
    can(:read, Network)
  end

  module Cached
    def permit_rules
    end
  end

  module NonCached
    def permit_rules
    end
  end
end
