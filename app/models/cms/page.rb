class Cms::Page <
    "Cms::Orm::#{ComfortableMexicanSofa.config.backend.to_s.classify}::Page".constantize

  key :is_protected, Boolean, :default => false
  key :controller, String
  key :master_path, String
  key :controller_path, String
  key :error_status, Integer

  # Context for pages
  belongs_to :master
  belongs_to :deployment
  belongs_to :network
  belongs_to :route
  belongs_to :service
  belongs_to :vehicle_journey

  attr_accessible :is_protected
  attr_accessible :master, :master_id
  attr_accessible :deployment, :deployment_id
  attr_accessible :network, :network_id
  attr_accessible :route, :route_id
  attr_accessible :service, :service_id
  attr_accessible :vehicle_journey, :vehicle_journey_id
  attr_accessible :master_path
  attr_accessible :controller_path

  # Full url for a page
  # TODO: SSL
  def url_with_port(port = nil)
    port_literal = port ? ":#{port}" : ""
    "http://" + "#{self.site.hostname}#{port_literal}/#{site.path}/#{self.full_path}".squeeze("/")
  end

  def website
    return master
  end

  def website_id
    return master_id
  end

  def master!
    return self.master if self.master
    self.parent.master! if self.parent
  end

  def deployment!
    return self.deployment if self.deployment
    self.parent.deployment! if self.parent
  end

  def network!
    return self.network if self.network
    self.parent.network! if self.parent
  end

  def route!
    return self.route if self.route
    self.parent.route! if self.parent
  end

  def service!
    return self.service if self.service
    self.parent.service! if self.parent
  end

  def vehicle_journey!
    return self.vehicle_journey if self.vehicle_journey
    self.parent.vehicle_journey! if self.parent
  end

  def redirect_path
    path = self.controller_path
    obj = nil
    if path
      path = path.gsub(":website_id", obj) if (obj = website_id)
      path = path.gsub(":master_id", obj.id) if (obj = master!)
      path = path.gsub(":deployment_id", obj.id) if (obj = deployment!)
      path = path.gsub(":network_id", obj.id) if (obj = network!)
      path = path.gsub(":route_id", obj.id) if (obj = route!)
      path = path.gsub(":service_id", obj.id) if (obj = service!)
      path = path.gsub(":vehicle_journey_id", obj.id) if (obj = vehicle_journey!)
    end
    return path.blank? ? nil : path
  end

  def export_attributes
    {
        :is_protected    => is_protected,
        :controller_path => controller_path,
        :master_path     => master_path
    }
  end

  def import_attributes(attributes)
    self.is_protected    = attributes[:is_protected] || false
    self.controller_path = attributes[:controller_path]
    self.master_path     = attributes[:master_path]
  end
end
