class Masters::Tools::StopPointsFinderController < Masters::MasterBaseController
  layout "masters/map-layout"

  def show
    authenticate_muni_admin!

  end
end