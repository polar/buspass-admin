class MuniAdminPermit < CanTango::UserPermit
  def initialize(ability)
    super
  end

  protected

  def dynamic_rules
    cannot(:delete, MuniAdmin) do |muni_admin|
      user == muni_admin
    end
    can(:read, MuniAdmin)
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
