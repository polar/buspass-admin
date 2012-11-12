class Masters::AdminController < Masters::MasterBaseController
  layout "empty"

  def show
    authenticate_muni_admin!
    get_master_context
    authorize_muni_admin!(:manage, @master)
  end

end
