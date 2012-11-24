class Masters::MuniAdminAuthenticationsController < Masters::MasterBaseController

  # This only gets called from masters/muni_admin_registrations/edit
  def destroy
    get_master_context
    @authentication = current_muni_admin.authentications.find(params[:id])
    if @authentication
      @authentication.destroy
      flash[:notice] = "Successfully destroyed authentication."
    end
    redirect_to edit_master_muni_admin_registration_path(@master, current_muni_admin)
  end

end