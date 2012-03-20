class PlannerRolePermit < CanTango::RolePermit
  def initialize(ability)
    super
  end

  protected

  def dynamic_rules
    # user is a MuniAdmin

    can([:edit, :delete], Master) do |master|
      master.muni_owner === user && user.master === master
    end
    can([:edit, :delete], Municipality) do |muni|
      muni.owner === user && user.master === muni.master &&
        muni.master.muni_owner === user
    end
  end

  def permit_rules
    can([:read, :create], Municipality)
    can([:read, :create], Network)
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
