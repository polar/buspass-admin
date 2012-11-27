class Masters::MuniAdminRegistrationsController < Masters::MasterBaseController

  def new
    get_master_context
    @authentication = Authentication.find session[:muni_admin_oauth_id]
    if @authentication
      muni_admin = MuniAdmin.find_by_authentication_id(@authentication.id)
      if muni_admin
        redirect_to edit_master_muni_admin_registration_path(@master, muni_admin), :notice => "edit"
      else
        @muni_admin = MuniAdmin.new()
        @muni_admin.name = @authentication.name
        @muni_admin.email = @authentication.last_info["email"]
        @muni_admin.master = @master
      end
    else
      redirect_to muni_admin_sign_in_path(:master_id => @master.id), :notice => "You need to authenticate first."
    end
  end

  def edit
    get_master_context
    authenticate_muni_admin!

    @muni_admin = current_muni_admin
    # Note: This authentication is the new one that the MuniAdmin just created.
    # we use it as it is the most recent. So, the MuniAdmin switched authentications.
    @authentication = @muni_admin.authentications.find session[:muni_admin_oauth_id]
    if @authentication
      @authentications = @muni_admin.authentications - [@authentication]
      @providers = BuspassAdmin::Application.oauth_providers - @muni_admin.authentications.map {|a| a.provider.to_s }
      @oauth_options = "?tpauth=amend_muni_admin&master_id=#{@master.id}&muni_admin_auth=#{session[:session_id]}&failure_path=#{edit_master_muni_admin_registration_path(@master, @muni_admin)}"
    else
      raise NotFoundError
    end
  end

  #
  # This gets called from a redirect from new_registration
  #
  def create
    get_master_context

    if current_muni_admin
      flash[:notice] = "You are already signed in."
      redirect_to edit_master_muni_admin_registration_path(@master, current_muni_admin)
      return
    end

    @authentication = Authentication.find session[:muni_admin_oauth_id]
    if @authentication
      @muni_admin = MuniAdmin.new(params[:muni_admin])
      icode = @muni_admin.auth_code.to_i
      auth_code = @master.muni_admin_auth_codes.select {|ac| ac.code == icode}.first
      if auth_code
        @muni_admin.add_roles(:planner) if auth_code.planner
        @muni_admin.add_roles(:operator) if auth_code.operator
        @muni_admin.authentications << @authentication
        @muni_admin.master = @master
        @muni_admin.save

        @master.muni_admin_auth_codes.build(auth_code.attributes.except(:code))
        @master.muni_admin_auth_codes.destroy!(auth_code)
        # destroy! will reload the instance so that the identity map will get the update
        session[:muni_admin_id] = @muni_admin.id
        redirect_to edit_master_muni_admin_registration_path(@master, @muni_admin), :notice => "Registered and Signed In!"
      else
        @muni_admin.errors.add(:auth_code, "Invalid Authorization Code")
        flash[:error] = "Invalid Authorization Code. Please see your Super Administrator"
        render :new
      end
    else
      redirect_to master_muni_admin_sign_in_path( @master), "You need to authenticate first."
    end
  end

  #
  # This gets called from a redirect from edit_registration
  def update
    get_master_context
    authenticate_muni_admin!
    tpauth = Authentication.find session[:muni_admin_oauth_id]
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