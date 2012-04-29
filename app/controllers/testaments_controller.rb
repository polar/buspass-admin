class TestamentsController < ApplicationController

  def index
    @testaments = Testament.all
    if @testaments.size == 1
      redirect_to :action => :show, :id => @testaments[0].id
    end
  end

  def show
    @testament = Testament.find(params[:id])
    @municipality = @testaments.municipality
    @master = @municipality.master
    @loginUrl = api_testament_path(@testament)
    render :layout => "webmap"
  end

  def api
    @testament = Testament.find(params[:id])
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
end
