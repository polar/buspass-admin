class ActivementsController < ApplicationController

  # May should more if user is logged in.
  def index
    authenticate_muni_admin!
    authorize_muni_admin!(:read, Activement)

    @activements = Activement.all
    if @activements.size == 1
      redirect_to activement_path(@activements[0])
    end
  end

  def show
    authenticate_muni_admin!
    @activement = Activement.find(params[:id])

    authorize_muni_admin!(:read, @activement)

    @municipality = @activement.municipality
    @master = @municipality.master
    @loginUrl = api_activement_path(@activement)
    render :layout => "webmap"
  end

  def api
    authenticate_muni_admin!
    @activement = Activement.find(params[:id])

    authorize_muni_admin!(:read, @activement)

    @municipality = @activement.municipality
    @master = @municipality.master
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

  protected

  def authorize_muni_admin!(action, obj)
    raise CanCan::AccessDenied if muni_admin_cannot?(action, obj)
  end

end
