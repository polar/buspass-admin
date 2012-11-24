class Masters::UserAuthenticationsController < Masters::MasterBaseController

  # This only gets called from masters/user_registrations/edit
  def destroy
    get_master_context
    @authentication = current_user.authentications.find(params[:id])
    if @authentication
      @authentication.destroy
      flash[:notice] = "Successfully destroyed authentication."
    end
    redirect_to edit_master_user_registration_path(@master, current_user)
  end

end