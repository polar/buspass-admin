class Masters::MuniAdminAuthenticationsController < Masters::MasterBaseController

  def create
    auth = request.env["rack.auth"]
    current_muni_admin.authentications.find_or_create_by_provider_and_uid(auth['provider'], auth['uid'])
    flash[:notice] = "Authentication successful."
    redirect_to edit_master_muni_admin_registration_path(@master, current_muni_admin)
  end

  def destroy
    @authentication = current_muni_admin.authentications.find(params[:id])
    @authentication.destroy
    flash[:notice] = "Successfully destroyed authentication."
    redirect_to edit_master_muni_admin_registration_path(@master, current_muni_admin)
  end

end