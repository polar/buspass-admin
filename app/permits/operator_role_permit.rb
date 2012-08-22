class OperatorRolePermit < CanTango::RolePermit
  def initialize(ability)
    super
  end

  protected

  def dynamic_rules

    # user is a MuniAdmin

    can(:read, Master) do |master|
      user.master == master
    end
    can([:read], Deployment) do |deployment|
      user.master == deployment.master
    end
    can([:deploy], Deployment) do |deployment|
      user.master == deployment.master && !deployment.is_active?
    end
    can(:read, Network) do |network|
      user.master == network.master
    end
    can([:edit, :delete], Testament) do |testament|
      user.master == testament.master
    end
    can([:edit, :delete], Activement) do |activement|
      user.master == activement.master
    end
  end

  def permit_rules
    can(:create, Testament)
    can(:create, Activement)
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
