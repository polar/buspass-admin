class ActivementsController < ApplicationController

  # May should more if user is logged in.
  def index
    authenticate_customer!
    authorize_customer!(:read, Activement)

    @activements = Activement.all
    if @activements.size == 1
      redirect_to activement_path(@activements[0])
    end
  end

  def show
    @activement = Activement.find(params[:id])
    @deployment = @activement.deployment
    @master = @deployment.master

    authenticate_muni_admin!
    authorize_muni_admin!(:read, @activement)

    @loginUrl = api_activement_path(@activement)
    render :layout => "webmap"
  end

  def api
   # authenticate_muni_admin!
    @activement = Activement.find(params[:id])

   # authorize_muni_admin!(:read, @activement)

    @deployment = @activement.deployment
    @master = @deployment.master
    @api = {
        "majorVersion"=> 1,
        "minorVersion"=> 0,
        "getRoutePath" => route_activement_webmap_path(@activement),
        "getRouteJourneyIds" => route_journeys_activement_webmap_path(@activement),
        "getRouteDefinition" => routedef_activement_webmap_path(@activement),
        "getJourneyLocation" => curloc_activement_webmap_path(@activement)
    }

    respond_to do |format|
      format.json { render :json => @api }
    end
  end


end
