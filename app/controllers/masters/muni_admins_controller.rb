class Masters::MuniAdminsController < Masters::MasterBaseController

  helper_method :sort_column, :sort_direction

  def index
    get_master_context
    authenticate_muni_admin!
    authorize_muni_admin!(:read, MuniAdmin)

    @roles       = MuniAdmin::ROLE_SYMBOLS
    @muni_admins = MuniAdmin.where(:master_id => @master.id)
                            .search(params[:search])
                            .order(sort_column => sort_direction)
                            .paginate(:page => params[:page], :per_page => 20)

    respond_to do |format|
      format.html # index.html.erb
      format.json { render :json => @muni_admins }
      format.js # render index.js.erb
    end
  end

  def edit
    get_master_context
    @muni_admin = MuniAdmin.find(params[:id])
    authorize_muni_admin!(:edit, @muni_admin)
  end

  def show
    get_master_context
    @muni_admin = MuniAdmin.find(params[:id])
    authorize_muni_admin!(:read, @muni_admin)

    respond_to do |format|
      format.json { render :json => @muni_admin }
    end
  end

  def new
    get_master_context
    authorize_muni_admin!(:create, MuniAdmin)
    @muni_admin        = MuniAdmin.new()
    @muni_admin.master = @master

    respond_to do |format|
      format.html # new.html.erb
      format.json { render :json => @muni_admin }
    end
  end

  def create
    get_master_context
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
    get_master_context
    attrs       = params[:muni_admin]
    @muni_admin = MuniAdmin.find(params[:id])
    if !@muni_admin || @muni_admin.master != @master
      raise NotFoundError.new("Administrator #{params[:id]} does not exist.")
    end
    authorize_muni_admin!(:edit, @muni_admin)

    @roles = MuniAdmin::ROLE_SYMBOLS

    params[:muni_admin] ||= { }
    params[:muni_admin][:role_symbols] ||= { }

    @alt = params[:muni_admin][:alt]

    # Security, don't let anything other than these keys get assigned.
    # We don't want some bogon changing the master_id, etc.
    params[:muni_admin].slice!(:email, :name, :role_symbols)

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
    get_master_context
    @muni_admin = MuniAdmin.find(params[:id])
    authorize_muni_admin!(:delete, @muni_admin)
    if @muni_admin
      @deployments = Deployment.where(:owner_id => @muni_admin.id).all
      render :layout => "masters/normal-layout"
    else
      flash[:error] = "Administrator #{params[:id]} does not exist."
      redirect_to master_muni_admins_path(@master)
    end
  end

  # Only comes in via HTML from destroy_confirm
  def destroy_confirmed
    get_master_context
    authenticate_muni_admin!
    @muni_admin = MuniAdmin.find(params[:id])

    if (current_muni_admin == @muni_admin)
      flash[:error] = "You cannot delete yourself."
      redirect_to master_muni_admins_path(@master)
      return
    end

    authorize_muni_admin!(:delete, @muni_admin)

    if @muni_admin
      if !@muni_admin.deployments.empty?
        @deployments = @muni_admin.deployments
        # TODO: Could we use a better confirmation token?
        if params[:confirmed] == "#{current_muni_admin.id}"
          @deployments.each do |deployment|
            deployment.owner = current_muni_admin
            deployment.save
          end
          # We must reload or we will destroy the deployments.
          @muni_admin.reload
          flash[:notice] = "Administrator #{@muni_admin.name} #{@muni_admin.email} has been removed."
          @muni_admin.destroy
          # THis was an HTML call from destroy_confirm
          redirect_to master_muni_admins_path(@master)
        else
          flash[:error] = "Confirm token invalid. Please go back to Administrators Page and retry."
          redirect_to master_muni_admins_path(@master)
        end
      else
        flash[:notice] = "Administrator #{@muni_admin.name} #{@muni_admin.email} has been removed."
        @muni_admin.destroy
        redirect_to master_muni_admins_path(@master)
      end
    else
      flash[:error] = "Administrator #{params[:id]} does not exist."
      redirect_to master_muni_admins_path(@master)
    end
  end

  # Only comes in via JS
  def destroy
    get_master_context
    authenticate_muni_admin!
    @muni_admin = MuniAdmin.find(params[:id])

    if (current_muni_admin == @muni_admin)
      flash[:error] = "You cannot delete yourself."
      @error = true
      return
    end

    authorize_muni_admin!(:delete, @muni_admin)

    if @muni_admin
      if !@muni_admin.deployments.empty?
        @redirect = destroy_confirm_master_muni_admin_path(@master, @muni_admin)
      else
        flash[:notice] = "Administrator #{@muni_admin.email} has been removed."
        @muni_admin.destroy
      end
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