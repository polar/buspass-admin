class Masters::MunicipalitiesController < Masters::MasterBaseController

  def index
    @municipalities = Municipality.where(:master_id => @master.id).all
  end

  def show
    @municipality = Municipality.find(params[:id])
  end

  def new
    authorize!(:create, Municipality)

    @municipality = Municipality.new
    @municipality.mode = :plan
    @municipality.display_name = @master.name
    @municipality.location = @master.location
    @municipality.master = @master
  end

  def edit
    @municipality = Municipality.find(params[:id])
    authorize!(:create, @municipality)
  end

  def create
    authorize!(:create, Municipality)

    @municipality = Municipality.new(params[:municipality])
    @municipality.mode = :plan
    @municipality.owner  = current_muni_admin

    # The municipality database will be unique to its instance, but we can stuff
    # the first one in the local masterdb.
    #@municipality.dbname              = @master.dbname + "#{@deployment.name}"
    #@municipality.masterdb            = @master.database.name
    @municipality.master = @master

    @municipality.display_name = @master.name
    @municipality.location = @master.location

    @municipality.ensure_slug()
    # TODO: Fix URL
    @municipality.hosturl = "http://#{@municipality.slug}.busme.us/#{@municipality.slug}" # hopeful
    error = ! @municipality.save
    if error
      flash[:error] = "Could not create deployment"
    end
    respond_to do |format|
      format.html {
        if error
          render :new
        else
          redirect_to master_municipalities_path
        end

      }
    end
  end

  def update
    @municipality = Municipality.find(params[:id])
    if (@municipality.nil?)
      throw "Not Found"
    end
    authorize!(:edit, @municipality)

    @municipality.update_attributes(params[:municipality])
    @municipality.master = @master
    @municipality.owner  = current_muni_admin

    @municipality.display_name = @master.name
    @municipality.location = @master.location

    @municipality.ensure_slug()
    # TODO: Fix URL
    @municipality.hosturl = "http://#{@municipality.slug}.busme.us/#{@municipality.slug}" # hopeful
    error = ! @municipality.save
    if error
      flash[:error] = "Could not update deployment"
    end
    respond_to do |format|
      format.html {
        if error
          render :edit
        else
          flash[:notice] = "Deployment has been successfully updated."
          redirect_to master_municipality_path(@municipality, :master_id => @master)
        end
      }
    end
  end

  def check
    @municipality = Municipality.find(params[:id])
    if (@municipality.nil?)
      throw "Not Found"
    end
    authorize!(:read, @municipality)
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
    @municipality = Municipality.where(:master_id => @master.id, :id => params[:id]).first
    if (@municipality.nil?)
      throw "Not Found"
    end
    authorize!(:delete, @municipality)
    @municipality.delete
    redirect_to master_municipalities_path(:master_id => @master.id)
  end

  def map
    @municipality = Municipality.where(:master_id => @master.id, :id => params[:id]).first
    if (@municipality.nil?)
      throw "Not Found"
    end
    authorize!(:read, @municipality)
    @routes = @municipality.routes
    @routes = @routes.sort { |s1, s2| codeOrd(s1.code, s2.code) }
    render :layout => "webmap"
  end

  def deploy
    @municipality = Municipality.where(:master_id => @master.id, :id => params[:id]).first
    if (@municipality.nil?)
      throw "Not Found"
    end
    authorize!(:deploy, @master)
    authorize!(:deploy, @municipality)
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
    @municipality = Municipality.where(:master_id => @master.id, :id => params[:id]).first
    if (@municipality.nil?)
      throw "Not Found"
    end
    authorize!(:deploy, @master)
    authorize!(:deploy, @municipality)
    @testament = Testament.where(:master_id => @master.id).first
    if (@testament == nil)
      @testament = Testament.new(:master => @master)
    end
    @testament.municipality = @municipality
    if @municipality.save
      if @testament.save
        redirect_to map_testament_run_path(@testament)
      else
        @municipality.save
      end
    end
  end

  def api
    @municipality = Municipality.where(:master_id => @master.id, :id => params[:id]).first
    if (@municipality.nil?)
      throw "Not Found"
    end
    authorize!(:read, @municipality)
    @api = {
        :majorVersion => 1,
        :minorVersion => 0,
        "getRoutePath" => route_master_municipality_webmap_path(@municipality, :master_id => @master.id),
        "getRouteJourneyIds" => route_journeys_master_municipality_webmap_path(@municipality, :master_id => @master.id),
        "getRouteDefinition" => routedef_master_municipality_webmap_path(@municipality, :master_id => @master.id),
        "getJourneyLocation" => curloc_master_municipality_webmap_path(@municipality, :master_id => @master.id)
    }

    respond_to do |format|
      format.json { render :json => @api }
    end
  end
end