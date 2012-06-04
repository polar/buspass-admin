class MastersController < MastersBaseController
  include PageUtils
  layout "empty"

  def deployment
    @master = Master.find(params[:id])
    if @master
      @deployment = Deployment.where(:master_id => @master.id).first
      if @deployment
        redirect_to deployment_path(@deployment)
      else
        render :text => "Municipality's Active Deployment Not Found", :status => 404
      end
    else
      render :text => "Municipality Not Found", :status => 404
    end
  end

  def testament
    @master = Master.find(params[:id])
    if @master
      @testament = Testament.where(:master_id => @master.id).first
      if @testament
        redirect_to testament_path(@testament)
      else
        render :text => "Municipality's Testing Deployment Not Found", :status => 404
      end
    else
      render :text => "Municipality Not Found", :status => 404
    end
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
    @site = ensure_main_admin_site()
  end

  def show
    @master = Master.find(params[:id])
    if @master.nil?
      raise "Not found"
    end
    @deployment = Deployment.where(:master_id => @master.id).first
    @testament = Testament.where(:master_id => @master.id).first
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
      @master.save!

      master = @master

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

      @muni_admin = MuniAdmin.new(current_admin.attributes.slice("encrypted_password", "email", "name"))
      @muni_admin.master = local_master
      @muni_admin.disable_empty_password_validation() # Keeps from arguing for a non-empty password.
      @muni_admin.add_roles([:super, :planner, :operator])

      @muni_admin.save!
      # This is the owner of the Master in the Muni realm.
      master.muni_owner = @muni_admin

      master.ensure_slug
      master.host = "#{master.slug}.busme.us"
      master.save!


      # create the first Municipality from the Master in the masters database because
      # it has the same name. The slug is where we infer the database name..
      #Municipality.set_database_name(local_masterdb)

      @municipality                     = Municipality.new()
      @municipality.mode                = :plan
      @municipality.status              = :plan
      @municipality.name                = local_master.name
      @municipality.display_name        = local_master.name
      @municipality.location            = local_master.location
      @municipality.owner               = @muni_admin
      # The municipality database will be unique to its instance, but we can stuff the first one in the local masterdb.
      @municipality.dbname              = local_masterdb
      @municipality.masterdb            = local_masterdb
      @municipality.master = local_master

      @municipality.ensure_slug()
      @municipality.hosturl = "http://#{@municipality.slug}.busme.us/#{@municipality.slug}" # hopeful

      @municipality.save!

      create_master_admin_site(@master)
      create_deployment_page(@master, @municipality)

        redirect_to master_path(@master)
  rescue Exception => boom
    @master.delete if @master
    @municipality.delete if @municipality
    @muni_admin.delete if @muni_admin
    raise boom
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

  protected

  def ensure_main_admin_site
    site = Cms::Site.find_by_identifier("busme-main")

    if site.nil?
      site = Cms::Site.create!(
          :path       => "admin",
          :identifier => "busme-main",
          :label      => "Main Administration Pages",
          :hostname   => "busme.us"
      )

      layout = site.layouts.create!(
          :identifier => "default",
          :app_layout => "application",
          :content    => "{{ cms:page:content }}")

      root = site.pages.create!(
          :slug              => "main",
          :label             => "Master Municipalities",
          :layout            => layout,
          :blocks_attributes => [{
                                     :identifier => "content",
                                     :content    => "{{ cms:bus:masters }}"
                                 }])
      newp = site.pages.create!(
          :slug              => "new",
          :label             => "New Master Municipality",
          :layout            => layout,
          :parent            => root,
          :blocks_attributes => [{
                                     :identifier => "content",
                                     :content    => "{{ cms:bus:master:new }}"
                                 }])
    end
    return site
  end
end