class MuniAdminPermit < CanTango::UserPermit
  def initialize(ability)
    super
  end

  protected

  def dynamic_rules
    cannot(:delete, MuniAdmin) do |muni_admin|
      user == muni_admin
    end
    can(:abort, Network) do |network|
      network.processing_lock == user
    end
  end

  def permit_rules
    can(:read, MuniAdmin)
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
