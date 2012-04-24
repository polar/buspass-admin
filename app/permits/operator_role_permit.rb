class OperatorRolePermit < CanTango::RolePermit
  def initialize(ability)
    super
  end

  protected

  def permit_rules
    can(:read, Network)
    can(:deploy, Master)
    can(:deploy, Municipality)
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
