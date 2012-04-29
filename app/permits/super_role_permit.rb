class SuperRolePermit < CanTango::RolePermit
    def initialize(ability)
        super
    end

  protected

  def dynamic_rules
    cannot(:delete, MuniAdmin) do |muni_admin|
       muni_admin === user
    end
  end

  def permit_rules
    can(:read, Network)
    can(:manage, MuniAdmin)
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
