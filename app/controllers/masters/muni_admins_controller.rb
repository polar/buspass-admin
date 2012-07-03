class Masters::MuniAdminsController < Masters::MasterBaseController
  helper_method :sort_column, :sort_direction

  def index
    authorize!(:read, MuniAdmin)

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
    authorize!(:read, MuniAdmin)

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
    authorize!(:edit, @muni_admin)
  end

  def show
    @muni_admin = MuniAdmin.find(params[:id])
    authorize!(:read, @muni_admin)

    respond_to do |format|
      format.json { render :json => @muni_admin }
    end
  end

  def new
    authorize!(:create, MuniAdmin)
    @muni_admin        = MuniAdmin.new()
    @muni_admin.master = @master

    respond_to do |format|
      format.html # new.html.erb
      format.json { render :json => @muni_admin }
    end
  end

  def create
    authorize!(:create, MuniAdmin)

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
    authorize!(:edit, @muni_admin)

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
    authorize!(:delete, @muni_admin)
    if @muni_admin
      @masters        = Master.where(:owner_id => @muni_admin.id).all
      @municipalities = Municipality.where(:owner_id => @muni_admin.id).all
      if @muni_admin.municipalities.empty?
        @muni_admin.destroy
        redirect_to master_muni_admins_path(@master)
      else
      end
    else
      redirect_to master_muni_admin_path(:master_id => @master.id)
    end
  end

  def destroy
    @muni_admin = MuniAdmin.find(params[:id])
    authorize!(:delete, @muni_admin)
    @muni_admin.destroy

    respond_to do |format|
      format.html { redirect_to master_muni_admins_path(@master) }
      format.json { head :no_content }
      format.js # destroy.htm.erb
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