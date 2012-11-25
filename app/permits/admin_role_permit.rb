class AdminRolePermit < CanTango::RolePermit
  def initialize(ability)
    super
  end

  protected

  def dynamic_rules
    can(:edit, Customer) do |cust|
      cust != user && user.is_a?(Customer)
    end
    cannot :delete, Customer do |cust|
      cust === user
    end
  end

  def permit_rules
    can(:manage, Cms::Site)
    can(:manage, Cms::Page)
    can(:delete, Master)
    can(:manage, Website)
    can(:manage, Customer)
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
