##
# This controller as @network already assigned.
#
class Muni::Plan::ServicesController < Muni::Plan::NetworkController

  def index
    @services = Service.where(:network_id => @network.id).sort(:route).all
  end

end