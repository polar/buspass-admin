class PlannerRolePermit < CanTango::RolePermit
  def initialize(ability)
    super
  end

  protected

  def dynamic_rules
    # user is a MuniAdmin

    can(:read, Master) do |master|
      user.master == master
    end
    can(:read, Deployment) do |deployment|
      user.master == deployment.master
    end
    can(:read, Network) do |network|
      user.master == network.master
    end
    can([:edit, :delete], Deployment) do |deployment|
      deployment.owner === user && user.master === deployment.master
    end
    can([:edit, :delete], Network) do |network|
      network.deployment.owner === user && user.master === network.master
    end
  end

  def permit_rules
    can([:create], Deployment)
    can([:create], Network)
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
