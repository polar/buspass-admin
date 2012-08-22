class SuperRolePermit < CanTango::RolePermit
    def initialize(ability)
        super
    end

  protected

  def dynamic_rules
    # User is MuniAdmin

    can([:read, :edit], Master) do |master|
      user.master == master
    end
    can([:delete], Activement) do |activement|
      user.master == activement.master
    end
    can([:delete], Testament) do |testament|
      user.master == testament.master
    end
    can([:read], Deployment) do |deployment|
      master == deployment.master
    end
    can([:edit, :delete, :deploy], Deployment) do |deployment|
      !deployment.is_active? && user.master == deployment.master
    end
    can([:read], Network) do |network|
      user.master == network.master
    end
    can([:edit, :delete, :abort], Network) do |network|
      !network.deployment.is_active? && user.master == network.master
    end
    can([:edit, :delete], Testament) do |testament|
      user.master == testament.master
    end
    can([:edit, :delete], Activement) do |activement|
      user.master == activement.master
    end
    cannot([:delete], MuniAdmin) do |muni_admin|
      muni_admin === user
    end
    can([:read, :edit, :delete], MuniAdmin) do |muni_admin|
      user.master == muni_admin.master
    end
    can([:read, :edit, :delete], User) do |user1|
      user.master == user1.master
    end
  end

  def permit_rules
    can(:create, Network)
    can(:create, Deployment)
    can(:create, MuniAdmin)
    can(:read,   MuniAdmin)
    can(:create, User)
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
