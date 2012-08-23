class Masters::MuniAdminRegistrationsController < Masters::MasterBaseController


  def new
    @authentication = Authentication.find session[:tpauth_id]
    if @authentication
      muni_admin = MuniAdmin.find_by_authentication_id(@authentication.id)
      if muni_admin
        redirect_to edit_registration_master_muni_admins_path(:master_id => @master.id), :notice => "edit"
      else
        @muni_admin = MuniAdmin.new()
        @muni_admin.name = @authentication.name
        @muni_admin.email = @authentication.last_info["email"]
        @muni_admin.master = @master
        # render form that posts to create_registration
        render :layout => "masters/normal-layout"
      end
    else
      redirect_to muni_admin_sign_in_path(:master_id => @master.id), :notice => "You need to authenticate first."
    end
  end

  def edit
    authenticate_muni_admin!

    @muni_admin = current_muni_admin
    @authentication = @muni_admin.authentications.find session[:tpauth_id]
    @authentications = @muni_admin.authentications - [@authentication]
    @providers = BuspassAdmin::Application.oauth_providers - @muni_admin.authentications.map {|a| a.provider.to_s }

    # We put this in the session in case the user adds an authentication.
    session[:tpauth] = :amend_muni_admin
    render :layout => "masters/normal-layout"
  end

  #
  # This gets called from a redirect from new_registration
  #
  def create
    tpauth = Authentication.find session[:tpauth_id]
    if tpauth
      @muni_admin = MuniAdmin.new(params[:muni_admin])
      @muni_admin.authentications << tpauth
      @muni_admin.master = @master
      @muni_admin.save
      session[:muni_admin_id] = @muni_admin.id
      redirect_to edit_master_muni_admin_registration_path(@master, @muni_admin), :notice => "Signed In!"
    else
      redirect_to master_muni_admin_sign_in_path( @master), "You need to authenticate first."
    end
  end

  #
  # This gets called from a redirect from edit_registration
  def update
    authenticate_muni_admin!
    # We put this in the session in case the user adds an authentication.
    session[:tpauth] = nil
    tpauth = Authentication.find session[:tpauth_id]
    if tpauth
      @muni_admin = current_muni_admin
      @muni_admin.update_attributes(params[:muni_admin])
      @muni_admin.authentications << tpauth
      @muni_admin.save
      redirect_to edit_master_muni_admin_registration_path(@master, @muni_admin), :notice => "Account Updated!"
    else
      redirect_to master_muni_admin_sign_in_path(@master), "You need to authenticate first."
    end
  end


end