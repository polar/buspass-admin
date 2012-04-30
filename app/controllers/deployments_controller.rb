class DeploymentsController < ApplicationController

  before_filter :authenticate_user!, :except => [:index, :show, :destroy, :api ]
  before_filter :authetnicate_muni_admin!, :only => [ :destroy ]

  def authorize!(action, obj)
    raise CanCan::PermissionDenied if muni_admin_cannot?(action, obj)
  end

  # May should more if user is logged in.
  def index
    @deployments = Deployment.all
    if @deployments.size == 1
      redirect_to deployment_path(@deployments[0])
    end
  end

  def show
    @deployment = Deployment.find(params[:id])
    @municipality = @deployment.municipality
    @master = @municipality.master
    @loginUrl = api_deployment_path(@deployment)
    render :layout => "webmap"
  end

  def api
    @deployment = Deployment.find(params[:id])
    @municipality = @deployment.municipality
    @master = @municipality.master
    @api = {
        "majorVersion"=> 1,
        "minorVersion"=> 0,
        "getRoutePath" => route_deployment_webmap_path(@deployment),
        "getRouteJourneyIds" => route_journeys_deployment_webmap_path(@deployment),
        "getRouteDefinition" => routedef_deployment_webmap_path(@deployment),
        "getJourneyLocation" => curloc_deployment_webmap_path(@deployment)
    }

    respond_to do |format|
      format.json { render :json => @api }
    end
  end
end
