class MastersController < ApplicationController

  before_filter :set_master_database

  def set_master_database
    #Master.set_database_name(@database)
  end

  before_filter :authenticate_admin!, :except => [:index, :show]
  #load_and_authorize_resource

  def authorize!(action, obj)
    raise CanCan::AccessDenied if admin_cannot?(action, obj)
  end

  def index
    if admin_signed_in?
      @masters = case params[:purpose]
        when "edit" then
          Master.editable_by(current_admin)
        when "read" then
          Master.readable_by(current_admin)
        else
          Master.all()
      end
    else
      @masters = Master.all
    end
  end

  def show
    @master = Master.find(params[:id])
    if @master.nil?
      raise "Not found"
    end
    authorize!(:read, @master)
  end

  def new
    authorize!(:create, Master)
    @master = Master.new
    # submits to create
  end

  def edit
    @master = Master.find(params[:id])
    authorize!(:edit, @master)
    # submits to update
  end

  def create
    puts ("ADMIN #{current_admin}")
    authorize!(:create, Master)

    location = params[:master][:location]
    if location != nil
      params[:master][:location] = view_context.from_location_str(location)
    end

    local_master = nil
    begin
      @master       = Master.new(params[:master])
      @master.owner = current_admin

      # TODO: These dbnames really should be GUIDs, but for Development.
      if Rails.env == "development"
        @master.ensure_slug()
        dbname = "#Busme-#{Rails.env}-#{@master.slug}"
      else
        # We use the id of the MasterMunicipality for a unique name.
        dbname = "#Busme-#{Rails.env}-#{@master.id.to_s}"
      end

      @master.dbname = dbname
      @error         = !@master.save

      master = @master

      if @error
        flash[:error] = "cannot create the masters municipality"
        raise "Cannot Create"
      end

      logger.info("Creating New Municipality Database #{dbname} for Master #{@master.name}")

      # Save everything to the new database, which is the local masterdb.
      local_masterdb       = dbname

=begin
      # We need to save again, but in the new database, as a place holder and default information.
      #MongoMapper.database = local_masterdb
      #Master.set_database_name(local_masterdb)

      local_master        = Master.new(params[:master])
      local_master.owner  = nil # This has no relevance since it may be in a different site.
      local_master.dbname = local_masterdb
      @error              = !local_master.save

      if @error
        flash[:error] = "Could not create the Master DB for Municipality"
        @master.delete
        raise "cannot create the masters DB for the municipality."
      end

      # Master Municipality and MuniAdmins are in the "masters" database
      # for the whole masters Municipality. This DB will contain the
      # MuniAdmin, the GoogleUriViewPath cache, and the Municipalities in
=end
      local_master = master       # their various modes and deployments.

      #MuniAdmin.set_database_name(local_masterdb)

      muni_admin = MuniAdmin.new(current_admin.attributes.slice("encrypted_password", "email", "name"))
      muni_admin.master = local_master
      muni_admin.disable_empty_password_validation() # Keeps from arguing for a non-empty password.
      muni_admin.add_roles([:super, :planner, :operator])
      @error = !muni_admin.save

      if @error
        flash[:error] = "Could not create the Master DB for Municipality"
        local_master.delete
        @master.delete
        raise "cannot create the masters DB for the municipality."
      end

      # create the first Municipality from the Master in the masters database because
      # it has the same name. The slug is where we infer the database name..
      #Municipality.set_database_name(local_masterdb)

      municipality                     = Municipality.new()
      municipality.mode                = :plan
      municipality.status              = :plan
      municipality.display_name        = local_master.name
      municipality.location            = local_master.location
      municipality.owner               = muni_admin
      # The municipality database will be unique to its instance, but we can stuff
                                                                                         # the first one in the local masterdb.
      municipality.dbname              = local_masterdb
      municipality.masterdb            = local_masterdb
      municipality.master_municipality = local_master

      municipality.ensure_slug()
      municipality.hosturl = "http://#{municipality.slug}.busme.us/#{municipality.slug}" # hopeful

      @error = !municipality.save!

      if @error
        flash[:error] = "Could not create the Municipality in the new DB"
        muni_admin.delete
        local_master.delete
        @master.delete
        raise "cannot create the masters DB for the municipality."
      end

      redirect_to master_path(@master)

    rescue CanCan::AccessDenied => access_denied
      raise access_denied
    rescue Exception => boom
      respond_to do |format|
        format.html {
          if @error
            render :new
          else
            redirect_to master_path(@master)
          end
        }
        format.all do
          method = "to_#{request_format}"
          text   = { }.respond_to?(method) ? { }.send(method) : ""
          render :text => text, :status => :ok
        end
      end
    end
  end

  def update
    @master = Master.find(params[:id])
    authorize!(:edit, @master)

    location = params[:master][:location]
    if location != nil
      params[:master][:location] = view_context.from_location_str(location)
    end
    error = false
    if @master == nil
      flash[:error] = "Master Municipality #{params[:id]} doesn't exist"
      error         = true
    elsif @master.owner != current_admin
      @master.errors.add_to_base("You do not have permission to update this object")
      flash[:error] = "You do not have permission to update this object"
      error         = true
    else
      @master.update_attributes(params[:master])
      error = !@master.save
      if !error
        flash[:notice] = "You have successfully updated your municipality."
      else
        flash[:error] = "You couldn't update your municipality."
      end
    end
    respond_to do |format|
      format.html {
        if error
          render :edit
        else
          redirect_to master_path(@master)
        end
      }
      format.all do
        method = "to_#{request_format}"
        text   = { }.respond_to?(method) ? { }.send(method) : ""
        render :text => text, :status => :ok
      end
    end
  end

  def delete
    @master = Master.find(params[:id])
    authorize!(:delete, @master)

    if @master == nil
      flash[:error] = "Municipality #{params[:id]} doesn't exist"
      error         = true
    elsif @master.owner != current_admin
      @master.errors.add_to_base("You do not have permission to delete this object")
      error = true
    else
      @master.delete()
    end
    respond_to do |format|
      format.html {
        redirect_to municipalities_path
      }
      format.all do
        method = "to_#{request_format}"
        text   = { }.respond_to?(method) ? { }.send(method) : ""
        render :text => text, :status => :ok
      end
    end
  end

end