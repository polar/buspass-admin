class TestamentsController < ApplicationController

  def index
    authenticate_customer!
    authorize_customer!(:read, Testament)

    @testaments = Testament.all
    if @testaments.size == 1
      redirect_to testament_path(@testaments[0])
    end
  end

  def show
    @testament = Testament.find(params[:id])
    if @testament
      @deployment = @testament.deployment
      @master     = @testament.master

      authenticate_muni_admin!
      authorize_muni_admin!(:manage, @testament)

      @loginUrl = api_testament_path(@testament)
      @center = [@master.longitude.to_f, @master.latitude.to_f]
    else
      # See if we can get the master from the session
      @master = Master.find(session[:master_id])
      if @master
        authenticate_muni_admin!
        redirect_to master_path(@master)
      else
        raise NotFoundError
      end
    end
  end

  def api
    authenticate_muni_admin
    @testament = Testament.find(params[:id])
    authorize_muni_admin!(:manage, @testament)

    @testament = Testament.find(params[:id])

    @deployment = @testament.deployment
    @master = @deployment.master

    authenticate_muni_admin!
    authorize_muni_admin!(:read, @testament)

    @api = {
        "majorVersion"=> 1,
        "minorVersion"=> 0,
        "getRoutePath" => route_testament_webmap_path(@testament),
        "getRouteJourneyIds" => route_journeys_testament_webmap_path(@testament),
        "getRouteDefinition" => routedef_testament_webmap_path(@testament),
        "getJourneyLocation" => curloc_testament_webmap_path(@testament)
    }

    respond_to do |format|
      format.json { render :json => @api }
    end
  end

end
