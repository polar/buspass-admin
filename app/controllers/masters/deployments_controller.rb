class Masters::DeploymentsController < Masters::MasterBaseController
  include PageUtils

  def index
    get_master_context
    authenticate_muni_admin!
    @deployments = Deployment.where(:master_id => @master.id).all
  end

  def show
    get_master_context
    authenticate_muni_admin!
    @deployment = Deployment.find(params[:id])
    @show_actions = !@deployment.is_active? && muni_admin_can?(:edit, @deployment)
    @status = []
    if @deployment.is_active?
      if @deployment.activement
        @status = ["Deployment is active"]
      else
        @status = ["Deployment is active in testing."]
      end

    end
  end

  def new
    get_master_context
    authenticate_muni_admin!
    authorize_muni_admin!(:create, Deployment)
    @deployment = Deployment.new
  end

  def edit
    get_master_context
    authenticate_muni_admin!
    @deployment = Deployment.find(params[:id])
    authorize_muni_admin!(:create, @deployment)
  end

  MUNICIPALITY_UPDATE_ALLOWED_ATTRIBUTES = [ :name, :note ]

  def create
    get_master_context
    authorize_muni_admin!(:create, Deployment)

    muni_attributes = params[:deployment].slice(*MUNICIPALITY_UPDATE_ALLOWED_ATTRIBUTES)

    @deployment              = Deployment.new(muni_attributes)
    @deployment.owner        = current_muni_admin
    @deployment.master       = @master
    @deployment.display_name = @master.name
    @deployment.longitude    = @master.longitude
    @deployment.latitude     = @master.latitude

    @deployment.save!

    create_master_deployment_page(@master, @deployment)

    respond_to do |format|
      format.html {
        flash[:notice] = "Your new deployment has been successfully created."
        redirect_to master_deployments_path(@master)
      }
    end
  rescue Exception => boom
    @deployment.destroy if @deployment
    flash[:error] = "Could not create your new deployment."
    render :new
  end

  def update
    get_master_context
    @deployment = Deployment.find(params[:id])
    authorize_muni_admin!(:edit, @deployment)

    # This could possibly be the wrong controller.
    if @deployment.master != @master
      raise "Cannot alter deployment from different Master."
    end

    muni_attributes = params[:deployment].slice(*MUNICIPALITY_UPDATE_ALLOWED_ATTRIBUTES)

    slug_was = @deployment.slug

    @deployment.update_attributes(muni_attributes)
    @deployment.display_name = @master.name
    @deployment.latitude = @master.latitude
    @deployment.longitude = @master.longitude
    @deployment.save!

    if slug_was != @deployment.slug
      page       = @deployment.page
      page.label = @deployment.name
      page.slug  = @deployment.slug
      page.save!
    end
    respond_to do |format|
      format.html {
        flash[:notice] = "Deployment has been successfully updated."
        redirect_to master_deployment_path(@master, @deployment)
      }
    end
  rescue Exception => boom
    flash[:error] = "Could not update deployment"
    render :action => :edit
  end

  def check
    get_master_context
    @deployment = Deployment.find(params[:id])
    authorize_muni_admin!(:read, @deployment)
    @status = @deployment.activement_check

    # Hide or Show the deploy button. Only show on a deployment that can be deployed.
    @show_deploy_button = false
    if @status.empty?
      @status << "This plan is consistent and can be deployed."
      @show_deploy_button = muni_admin_can?(:deploy, @deployment)
    else
      @status = ["This plan may not be deployed because of the following:"] + @status
    end
  end

  def destroy
    get_master_context
    @deployment = Deployment.find(params[:id])
    authorize_muni_admin!(:delete, @deployment)
    @deployment.destroy
    redirect_to master_deployments_path(@master)
  end

  def map
    get_master_context
    @deployment = Deployment.find(params[:id])
    authorize_muni_admin!(:read, @deployment)
    @routes = @deployment.routes
    @routes = @routes.sort { |s1, s2| codeOrd(s1.code, s2.code) }
  end

  def deploy
    get_master_context
    @deployment = Deployment.find(params[:id])
    authorize_muni_admin!(:deploy, @deployment)
    @status = []
    if @deployment.is_active?
      flash[:error] = "The deployment is already active."
      @status << "Deployment is active."
      render :show
      return
    end

    @activement = Activement.where(:master_id => @master.id).first
    if (@activement == nil)
      @activement = Activement.new(:master => @master)
    end
    if @activement.is_processing?
      flash[:error] = "You must stop the active deployment first."
      redirect_to master_active_path(@master)
    else
      @activement.deployment = @deployment
      if @activement.save
        flash[:notice] = "Deployment successfully submitted for activation. You need to explicitly start it."
        redirect_to master_active_path(@master)
      else
        flash[:error] = "Could not activate deployment"
        render :show
      end
    end
  end
  
  def testit
    get_master_context
    authenticate_muni_admin!
    @deployment = Deployment.find(params[:id])
    authorize_muni_admin!(:deploy, @master)
    authorize_muni_admin!(:deploy, @deployment)
    @testament = Testament.where(:master_id => @master.id).first
    if (@testament == nil)
      @testament = Testament.new(:master => @master)
    end
    @testament.deployment = @deployment
    if @testament.save
        redirect_to master_testament_path(@master, @testament)
    else
        flash[:error] = "Could not test deployment".
        redirect_to master_deployment_path(@master, @deployment)
    end
  end

  def map
    get_master_context
    @deployment = Deployment.find(params[:id])
    @networks = @deployment.networks
  end

  def api
    get_master_context
    @deployment = Deployment.find(params[:id])
    authorize_muni_admin!(:read, @deployment)
    @api = {
        :majorVersion => 1,
        :minorVersion => 0,
        "getRoutePath" => route_master_deployment_webmap_path(@master, @deployment),
        "getRouteJourneyIds" => route_journeys_master_deployment_webmap_path(@master, @deployment),
        "getRouteDefinition" => routedef_master_deployment_webmap_path(@master, @deployment),
        "getJourneyLocation" => curloc_master_deployment_webmap_path(@master, @deployment)
    }

    respond_to do |format|
      format.json { render :json => @api }
    end
  end

end