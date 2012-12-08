class ActivementsController < ApplicationController

  def index
    authenticate_customer!
    authorize_customer!(:read, Activement)

    @activements = Activement.all
    if @activements.size == 1
      redirect_to activement_path(@activements[0])
    end
  end

  def show
    logger.debug "PATH======#{request.original_fullpath}"
    logger.debug "FULLPATH=========#{request.fullpath}"
    @activement = Activement.find(params[:id])
    if @activement
      @deployment = @activement.deployment
      @master     = @activement.master

      authenticate_muni_admin!
      authorize_muni_admin!(:manage, @activement)

      @loginUrl = api_activement_path(@activement)
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
