class Masters::AdminController < Masters::MasterBaseController
  layout "empty"

  def show
    get_master_context
    authenticate_muni_admin!
    authorize_muni_admin!(:manage, @master)
  end

end
