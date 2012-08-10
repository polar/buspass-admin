class Masters::Tools::PathfinderController < Masters::MasterBaseController
  layout "empty"

  def show
    authenticate_muni_admin!

  end
end