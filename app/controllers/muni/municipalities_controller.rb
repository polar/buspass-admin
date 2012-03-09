class Muni::MunicipalitiesController < Muni::ApplicationController

  def index
    @municipalities = Municipality.all
  end
  def show

    @municipality = Municipality.find(params[:id])
  end

  def new
    @municipality = Municipality.new
    @municipality.mode = :plan
    @municipality.display_name = @master.name
    @municipality.location = @master.location

  end

  def create
    @municipality = Municipality.new(params[:municipality])
    @municipality.mode = :plan
    @municipality.master_municipality = @master
    @municipality.owner               = @master

    # The municipality database will be unique to its instance, but we can stuff
    # the first one in the local masterdb.
    #@municipality.dbname              = @master.dbname + "#{@deployment.name}"
    #@municipality.masterdb            = @master.database.name
    @municipality.master_municipality = @master

    @municipality.display_name = @master.name
    @municipality.location = @master.location

    @municipality.ensure_slug()
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
end