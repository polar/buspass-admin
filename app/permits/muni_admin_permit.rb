class MuniAdminPermit < CanTango::UserPermit
  def initialize(ability)
    super
  end

  protected

  def dynamic_rules
    can([:abort], Network) do |network|
      network.processing_lock == user
    end
    can(:read, Master) do |master|
      master == user.master
    end
  end

  def permit_rules
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
