class MuniAdminPermit < CanTango::UserPermit
  def initialize(ability)
    super
  end

  protected

  def dynamic_rules
    can([:abort], Network) do |network|
      puts "---------Networ Rules? #{user.id}"
      network.processing_lock == user
    end
  end

  def permit_rules
    puts "---------Permit Rules? #{user.id}"
    can(:read, MuniAdmin)
  end

  module Cached
    def permit_rules
      puts "----------Cached Rules? #{user.id}"
    end
  end

  module NonCached
    def permit_rules
      puts "---------NonCached Rules? #{user.id}"
    end
  end
end
