
# This adds to the Cms::Site in ComfortableMexicanSofa

class Cms::Site <
    "Cms::Orm::#{ComfortableMexicanSofa.config.backend.to_s.classify}::Site".constantize

  belongs_to :master, :class_name => "Master"
  key :protected, Boolean, :default => false

  attr_accessible :master, :master_id
  attr_accessible :protected

  def is_protected?
    self.protected
  end

  def base_path(port)
    port_literal = port ? ":#{port}" : ""
    host = master.base_host if master
    host ||= Rails.application.base_host
    prefix = master.slug if master
    prefix ||= ""
    "#{host}#{port_literal}/#{prefix}"
  end

  # TODO: SSL
  def site_url(port)
    "http://" + "#{base_path(port)}/#{self.path}"
    #"http://" + "#{self.site.hostname}#{port_literal}/#{site.path}".squeeze("/")
  end

  # Full url for a page
  def site_url_with_port(port = nil)
    "#{site_url(port)}".squeeze("/")
  end

end