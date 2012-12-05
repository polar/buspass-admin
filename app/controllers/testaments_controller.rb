class TestamentsController < ApplicationController

  def index
    authenticate_customer!
    authorize_customer!(:read, Testament)

    @testaments = Testament.all
    if @testaments.size == 1
      redirect_to :action => :show, :id => @testaments[0].id
    end
  end

  def show
    @testament = Testament.find(params[:id])

    @deployment = @testament.deployment
    @master = @deployment.master

    authenticate_muni_admin!
    authorize_muni_admin!(:read, @testament)

    @loginUrl = api_testament_path(@testament)
    @center = [@master.longitude.to_f, @master.latitude.to_f]
  end

  def api
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
