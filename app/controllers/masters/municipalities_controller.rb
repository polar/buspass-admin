class Masters::MunicipalitiesController < Masters::MasterBaseController
  include PageUtils

  def index
    authenticate_muni_admin!
    @municipalities = Municipality.where(:master_id => @master.id).all
  end

  def show
    authenticate_muni_admin!
    @municipality = Municipality.find(params[:id])
  end

  def new
    authenticate_muni_admin!
    authorize_muni_admin!(:create, Municipality)
    @municipality = Municipality.new
  end

  def edit
    authenticate_muni_admin!
    @municipality = Municipality.find(params[:id])
    authorize_muni_admin!(:create, @municipality)
  end

  MUNICIPALITY_UPDATE_ALLOWED_ATTRIBUTES = [ :name, :note ]

  def create
    authorize_muni_admin!(:create, Municipality)

    muni_attributes = params[:municipality].slice(*MUNICIPALITY_UPDATE_ALLOWED_ATTRIBUTES)

    @municipality              = Municipality.new(muni_attributes)
    @municipality.owner        = current_muni_admin
    @municipality.master       = @master
    @municipality.display_name = @master.name
    @municipality.longitude    = @master.longitude
    @municipality.latitude     = @master.latitude

    @municipality.save!

    create_master_deployment_page(@master, @municipality)

    respond_to do |format|
      format.html {
        flash[:notice] = "Your new deployment has been successfully created."
        redirect_to master_municipalities_path(@master)
      }
    end
  rescue Exception => boom
    @municipality.destroy if @municipality
    flash[:error] = "Could not create your new deployment."
    render :new
  end

  def update
    @municipality = Municipality.find(params[:id])
    authorize_muni_admin!(:edit, @municipality)

    # This could possibly be the wrong controller.
    if @municipality.master != @master
      raise "Cannot alter deployment from different Master."
    end

    muni_attributes = params[:municipality].slice(*MUNICIPALITY_UPDATE_ALLOWED_ATTRIBUTES)

    slug_was = @municipality.slug

    @municipality.update_attributes(muni_attributes)
    @municipality.display_name = @master.name
    @municipality.latitude = @master.latitude
    @municipality.longitude = @master.longitude
    @municipality.save!

    if slug_was != @municipality.slug
      page       = @municipality.page
      page.label = @municipality.name
      page.slug  = @municipality.slug
      page.save!
    end
    respond_to do |format|
      format.html {
        flash[:notice] = "Deployment has been successfully updated."
        redirect_to master_municipality_path(@master, @municipality)
      }
    end
  rescue Exception => boom
    flash[:error] = "Could not update deployment"
    render :action => :edit
  end

  def check
    @municipality = Municipality.find(params[:id])
    authorize_muni_admin!(:read, @municipality)
    @status = @municipality.deployment_check

    # Hide or Show the deploy button. Only show on a municipality that can be deployed.
    @show_deploy_button = false
    if @status.empty?
      @status << "This plan is consistent and can be deployed."
      @show_deploy_button = muni_admin_can?(:deploy, @master)
    else
      @status = ["This plan may not be deployed because of the following:"] + @status
    end
  end

  def destroy
    @municipality = Municipality.find(params[:id])
    authorize_muni_admin!(:delete, @municipality)
    @municipality.destroy
    redirect_to master_municipalities_path(@master)
  end

  def map
    @municipality = Municipality.find(params[:id])
    authorize_muni_admin!(:read, @municipality)
    @routes = @municipality.routes
    @routes = @routes.sort { |s1, s2| codeOrd(s1.code, s2.code) }
  end

  def deploy
    @municipality = Municipality.find(params[:id])
    authorize_muni_admin!(:deploy, @master)
    authorize_muni_admin!(:deploy, @municipality)
    @deployment = Deployment.where(:master_id => @master.id).first
    if (@deployment == nil)
      @deployment = Deployment.new(:master => @master)
    end
    @deployment.municipality = @municipality
    if @municipality.save
      if @deployment.save
        redirect_to map_deployment_run_path(@deployment)
      else
        @municipality.save
      end
    end
  end
  
  def testit
    @municipality = Municipality.find(params[:id])
    authorize_muni_admin!(:deploy, @master)
    authorize_muni_admin!(:deploy, @municipality)
    @testament = Testament.where(:master_id => @master.id).first
    if (@testament == nil)
      @testament = Testament.new(:master => @master)
    end
    @testament.municipality = @municipality
    if @municipality.save
      if @testament.save
        redirect_to master_testament_path(@master, :testament_id => @testament.id)
      else
        @municipality.save
      end
    end
  end

  def api
    @municipality = Municipality.find(params[:id])
    authorize_muni_admin!(:read, @municipality)
    @api = {
        :majorVersion => 1,
        :minorVersion => 0,
        "getRoutePath" => route_master_municipality_webmap_path(@master, @municipality),
        "getRouteJourneyIds" => route_journeys_master_municipality_webmap_path(@master, @municipality),
        "getRouteDefinition" => routedef_master_municipality_webmap_path(@master, @municipality),
        "getJourneyLocation" => curloc_master_municipality_webmap_path(@master, @municipality)
    }

    respond_to do |format|
      format.json { render :json => @api }
    end
  end
end