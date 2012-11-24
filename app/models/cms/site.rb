
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

  # Full url for a page
  # TODO: SSL
  def url_with_port(port = nil)
    port_literal = port ? ":#{port}" : ""
    "http://" + "#{master.base_host}#{port_literal}/#{master.slug}/#{self.path}".squeeze("/")
    #"http://" + "#{self.site.hostname}#{port_literal}/#{site.path}".squeeze("/")
  end

end