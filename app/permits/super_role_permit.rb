class SuperRolePermit < CanTango::RolePermit
    def initialize(ability)
        super
    end

  protected

  def dynamic_rules
    # User is MuniAdmin

    can([:read], MuniAdminAuthCode) do |code|
      code.master == master if user.is_a? MuniAdmin
    end
    can([:read, :edit], Master) do |master|
      user.master == master if user.is_a? MuniAdmin
    end
    can([:delete], Activement) do |activement|
      user.master == activement.master if user.is_a? MuniAdmin
    end
    can([:delete], Testament) do |testament|
      user.master == testament.master if user.is_a? MuniAdmin
    end
    can([:read], Deployment) do |deployment|
      master == deployment.master if user.is_a? MuniAdmin
    end
    can([:edit, :delete, :deploy], Deployment) do |deployment|
      !deployment.is_active? && user.master == deployment.master if user.is_a? MuniAdmin
    end
    can([:read], Network) do |network|
      user.master == network.master if user.is_a? MuniAdmin
    end
    can([:edit, :delete, :abort], Network) do |network|
      !network.deployment.is_active? && user.master == network.master if user.is_a? MuniAdmin
    end
    can([:edit, :delete], Testament) do |testament|
      user.master == testament.master if user.is_a? MuniAdmin
    end
    can([:edit, :delete], Activement) do |activement|
      user.master == activement.master if user.is_a? MuniAdmin
    end
    can([:read, :edit], MuniAdmin) do |muni_admin|
      user.master == muni_admin.master if user.is_a? MuniAdmin
    end
    can([:delete], MuniAdmin) do |muni_admin|
      muni_admin != user && user.master == muni_admin.master if user.is_a? MuniAdmin
    end
    can([:read, :edit, :delete], User) do |user1|
      user.master == user1.master if user.is_a? MuniAdmin
    end
  end

  def permit_rules
    can(:manage, Cms::Site)
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
