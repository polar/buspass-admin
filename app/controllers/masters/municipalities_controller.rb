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
    authorize!(:create, @municipality)

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
          redirect_to master_municipality_path(@municipality, :master_id => @master)
        end
      }
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
end