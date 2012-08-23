class Masters::MuniAdminsController < Masters::MasterBaseController

  helper_method :sort_column, :sort_direction

  def index
    authenticate_muni_admin!
    authorize_muni_admin!(:read, MuniAdmin)

    @roles       = MuniAdmin::ROLE_SYMBOLS
    @muni_admins = MuniAdmin.where(:master_id => @master.id)
                            .search(params[:search])
                            .order(sort_column => sort_direction)
                            .paginate(:page => params[:page], :per_page => 4)

    respond_to do |format|
      format.html # index.html.erb
      format.json { render :json => @muni_admins }
      format.js # render index.js.erb
    end
  end

  def admin
    authorize_muni_admin!(:read, MuniAdmin)

    @roles       = MuniAdmin::ROLE_SYMBOLS
    @muni_admins = MuniAdmin.where(:master_id => @master.id)
                            .search(params[:search])
                            .order(sort_column => sort_direction)
                            .paginate(:page => params[:page], :per_page => 4)

    respond_to do |format|
      format.html # index.html.erb
      format.json { render :json => @muni_admins }
      format.js # render index.js.erb
    end
  end

  def edit
    @muni_admin = MuniAdmin.find(params[:id])
    authorize_muni_admin!(:edit, @muni_admin)
  end

  def show
    @muni_admin = MuniAdmin.find(params[:id])
    authorize_muni_admin!(:read, @muni_admin)

    respond_to do |format|
      format.json { render :json => @muni_admin }
    end
  end

  def new
    authorize_muni_admin!(:create, MuniAdmin)
    @muni_admin        = MuniAdmin.new()
    @muni_admin.master = @master

    respond_to do |format|
      format.html # new.html.erb
      format.json { render :json => @muni_admin }
    end
  end

  def create
    authorize_muni_admin!(:create, MuniAdmin)

    # Security, don't let anything other than these keys get assigned.
    # We don't want some bogon changing the master_id, etc.
    params[:muni_admin].slice!(:password, :password_confirmation, :email, :name, :role_symbols)

    @muni_admin        = MuniAdmin.new(params[:muni_admin])
    @muni_admin.master = @master

    respond_to do |format|
      if @muni_admin.save
        format.html { redirect_to @muni_admin, :notice => 'Admin was successfully created.' }
        format.json { render :json => @muni_admin, :status => :created, :location => @muni_admin }
      else
        format.html { render :action => "new" }
        format.json { render :json => @muni_admin.errors, :status => :unprocessable_entity }
      end
    end
  end

  def update
    attrs       = params[:muni_admin]
    @muni_admin = MuniAdmin.find(params[:id])
    if !@muni_admin || @muni_admin.master != @master
      raise "Not Found"
    end
    authorize_muni_admin!(:edit, @muni_admin)

    @roles = MuniAdmin::ROLE_SYMBOLS

    # Security, don't let anything other than these keys get assigned.
    # We don't want some bogon changing the master_id, etc.
    params[:muni_admin].slice!(:password, :password_confirmation, :email, :name, :role_symbols)

    if current_muni_admin == @muni_admin
      # We don't want you to alter your own roles.
      params[:muni_admin][:role_symbols] = @muni_admin.role_symbols
    end

    respond_to do |format|
      if @muni_admin.update_attributes(params[:muni_admin])
        format.html { redirect_to master_muni_admins_path(@master), :notice => 'Admin was successfully updated.' }
        format.json { head :no_content }
        format.js # update.js.erb
      else
        format.html { render :action => "edit" }
        format.json { render :json => @muni_admin.errors, :status => :unprocessable_entity }
        format.js # update.js.erb
      end
    end
  end

  def destroy_confirm
    @muni_admin = MuniAdmin.find(params[:id])
    authorize_muni_admin!(:delete, @muni_admin)
    if @muni_admin
      @deployments = Deployment.where(:owner_id => @muni_admin.id).all
      if @muni_admin.deployments.empty?
        @muni_admin.destroy
        redirect_to master_muni_admins_path(@master)
      else
        @deployments.each do |deployment|
          deployment.owner = current_muni_admin
          deployment.save
        end
        @muni_admin.reload
        @muni_admin.destroy
      end
    else
      redirect_to master_muni_admin_path(:master_id => @master.id)
    end
  end

  def destroy
    authenticate_muni_admin!
    @muni_admin = MuniAdmin.find(params[:id])
    authorize_muni_admin!(:delete, @muni_admin)

    if (current_muni_admin == @muni_admin)
      raise "Cannot delete self"
    end

    if @muni_admin
      @deployments = Deployment.where(:owner_id => @muni_admin.id).all
      if @muni_admin.deployments.empty?
        @muni_admin.destroy
        redirect_to master_muni_admins_path(@master)
      else
        @deployments.each do |deployment|
          deployment.owner = current_muni_admin
          deployment.save
        end
        @muni_admin.reload
        @muni_admin.destroy
      end
    end

    respond_to do |format|
      format.html { redirect_to master_muni_admins_path(@master) }
      format.json { head :no_content }
      format.js # destroy.htm.erb
    end
  end

  def new_registration
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

  def edit_registration
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
  def create_registration
    tpauth = Authentication.find session[:tpauth_id]
    if tpauth
      @muni_admin = MuniAdmin.new(params[:muni_admin])
      @muni_admin.authentications << tpauth
      @muni_admin.master = @master
      @muni_admin.save
      session[:muni_admin_id] = @muni_admin.id
      redirect_to edit_registration_master_muni_admins_path(@master), :notice => "Signed In!"
    else
      redirect_to muni_admin_sign_in_path(:master_id => @master.id), "You need to authenticate first."
    end
  end

  #
  # This gets called from a redirect from edit_registration
  def update_registration
    authenticate_muni_admin!
    # We put this in the session in case the user adds an authentication.
    session[:tpauth] = nil
    tpauth = Authentication.find session[:tpauth_id]
    if tpauth
      @muni_admin = current_muni_admin
      @muni_admin.update_attributes(params[:muni_admin])
      @muni_admin.authentications << tpauth
      @muni_admin.save
      redirect_to edit_registration_master_muni_admins_path(@master), :notice => "Account Updated!"
    else
      redirect_to muni_admin_sign_in_path(:master_id => @master.id), "You need to authenticate first."
    end
  end


  private

  def sort_column
    MuniAdmin.keys.keys.include?(params[:sort]) ? params[:sort] : "name"
  end

  def sort_direction
    [1, -1].include?(params[:direction].to_i) ? params[:direction].to_i : -1
  end
end