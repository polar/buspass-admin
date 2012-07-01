class Cms::Page <
    "Cms::Orm::#{ComfortableMexicanSofa.config.backend.to_s.classify}::Page".constantize

  key :is_protected, Boolean, :default => false
  key :controller, String
  key :master_path, String
  key :controller_path, String

  # Context for pages
  belongs_to :master
  belongs_to :municipality
  belongs_to :network
  belongs_to :route
  belongs_to :service
  belongs_to :vehicle_journey

  attr_accessible :is_protected
  attr_accessible :master, :master_id
  attr_accessible :municipality, :municipality_id
  attr_accessible :network, :network_id
  attr_accessible :route, :route_id
  attr_accessible :service, :service_id
  attr_accessible :vehicle_journey, :vehicle_journey_id
  attr_accessible :master_path
  attr_accessible :controller_path

  def master!
    return self.master if self.master
    self.parent.master if self.parent
  end
  def municipality!
    return self.municipality if self.municipality
    self.parent.municipality if self.parent
  end
  def network!
    return self.network if self.network
    self.parent.network if self.parent
  end
  def route!
    return self.route if self.route
    self.parent.route if self.parent
  end
  def service!
    return self.service if self.service
    self.parent.service if self.parent
  end
  def vehicle_journey!
    return self.vehicle_journey if self.vehicle_journey
    self.parent.vehicle_journey if self.parent
  end

  def redirect_path
    path = self.controller_path
    if path
      path = path.gsub(":master_id", obj.id) if (obj = master!)
      path = path.gsub(":municipality_id", obj.id) if (obj = municipality!)
      path = path.gsub(":network_id", obj.id) if (obj = network!)
      path = path.gsub(":route_id", obj.id) if (obj = route!)
      path = path.gsub(":service_id", obj.id) if (obj = service!)
      path = path.gsub(":vehicle_journey_id", obj.id) if (obj = vehicle_journey!)
    end
    return path.blank? ? nil : path
  end
end
