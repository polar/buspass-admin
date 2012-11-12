class AdminRolePermit < CanTango::RolePermit
  def initialize(ability)
    super
  end

  protected

  def dynamic_rules
    can(:edit, Customer) do |cust|
      cust != user
    end
    cannot :delete, Customer do |cust|
      cust === user
    end
  end

  def permit_rules
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
