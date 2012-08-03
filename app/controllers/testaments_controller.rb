class TestamentsController < ApplicationController

  def index
    @testaments = Testament.all
    if @testaments.size == 1
      redirect_to :action => :show, :id => @testaments[0].id
    end
  end

  def show
    authenticate_muni_admin!
    @testament = Testament.find(params[:id])

    authorize_muni_admin!(:read, @testament)

    @municipality = @testament.municipality
    @master = @municipality.master
    @loginUrl = api_testament_path(@testament)
  end

  def api
    authenticate_muni_admin!
    @testament = Testament.find(params[:id])

    authorize_muni_admin!(:read, @testament)

    @municipality = @testament.municipality
    @master = @municipality.master
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

  protected

  def authorize_muni_admin!(action, obj)
    raise CanCan::AccessDenied if muni_admin_cannot?(action, obj)
  end
end
