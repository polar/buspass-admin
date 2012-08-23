class MuniAdminAuthenticationsController < Masters::MasterBaseController
  def index
    @authentications = current_muni_admin.authentications if current_muni_admin
  end

  def create
    auth = request.env["rack.auth"]
    current_muni_admin.authentications.find_or_create_by_provider_and_uid(auth['provider'], auth['uid'])
    flash[:notice] = "Authentication successful."
    redirect_to edit_registration_master_muni_admins_path(@master)
  end

  def destroy
    @authentication = current_muni_admin.authentications.find(params[:id])
    @authentication.destroy
    flash[:notice] = "Successfully destroyed authentication."
    redirect_to edit_registration_master_muni_admins_path(@master)
  end

end