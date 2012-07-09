class SuperRolePermit < CanTango::RolePermit
    def initialize(ability)
        super
    end

  protected

  def dynamic_rules
    # User is MuniAdmin
    can(:edit, Master) do |master|
      master == user.master
    end
    cannot(:delete, MuniAdmin) do |muni_admin|
       muni_admin === user
    end
  end

  def permit_rules
    can(:read, Network)
    can(:manage, MuniAdmin)
    can(:manage, User)
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
