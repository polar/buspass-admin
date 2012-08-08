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
    can(:read, Municipality) do |municipality|
      user.master == municipality.master
    end
    can(:read, Network) do |network|
      user.master == network.master
    end
    can([:edit, :delete], Municipality) do |municipality|
      !municipality.is_active? && municipality.owner === user && user.master === municipality.master
    end
    can([:edit, :delete], Network) do |network|
      !network.municipality.is_active? && network.municipality.owner === user && user.master === network.master
    end
  end

  def permit_rules
    can([:create], Municipality)
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
