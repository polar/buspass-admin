class CustomerPermit < CanTango::UserPermit
  def initialize(ability)
    super
  end

  protected

  def dynamic_rules
    can([:edit, :delete], Master) do |master|
      master.owner === user
    end
  end

  def permit_rules
    can(:create, Master)
    can(:read, Master)
    can(:create, Deployment)
    can(:read, Deployment)
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
