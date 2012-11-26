class Masters::Deployments::NetworksController < Masters::Deployments::DeploymentBaseController
  include PageUtils

  def index
    authenticate_muni_admin!
    @networks = Network.where(:deployment_id => @deployment.id).all
    @networks.reject! { |n| n.is_locked? }
  end

  def new
    authenticate_muni_admin!
    authorize_muni_admin!(:create, Network)

    if @deployment.is_active?
      flash[:error] = "Deployment is active. You cannot create a new Network in it until that deployment is deactivated."
      redirect_to(:back)
      return
    end

    @network = Network.new
  end

  def show
    authenticate_muni_admin!
    @network = Network.find(params[:id])
    if @network && !@network.is_locked?
      authorize_muni_admin!(:read, @network)
    else
      flash[:error] = "Network is currently locked. Must wait to finish processing."
      redirect_to(:back)
    end
  end

  def edit
    authenticate_muni_admin!
    @network = Network.find(params[:id])
    if @network.deployment.is_active?
      flash[:error] = "Cannot edit Network. Network is currently active or in testing."
      render :show
      return
    end
    if @network && !@network.is_locked?
      authorize_muni_admin!(:edit, @network)
    else
      flash[:error] = "Network is currently being processed. Must wait for processing to finish."
      redirect_to(:back)
    end
  end

  NETWORK_UPDATE_ALLOW_ATTRIBUTES = [:name, :description]

  def create
    authorize_muni_admin!(:create, Network)

    network_attributes = params[:network].slice(*NETWORK_UPDATE_ALLOW_ATTRIBUTES)

    @network = Network.new(network_attributes)
    @network.deployment = @deployment
    @network.master = @master
    error = ! @network.save
    if error
      flash[:error] = "Cannot create network. #{@network.errors.message}"
      render :action => :new
    else
      create_master_deployment_network_page(@master, @deployment, @network)

      flash[:notice] = "Network #{@network.name} has been created."
      redirect_to master_deployment_network_path(@master, @deployment, @network)
    end
  rescue Exception => boom
    page_error = PageError.new({
                                   :request_url => request.url,
                                   :params     => params,
                                   :error      => boom.to_s,
                                   :backtrace  => boom.backtrace,
                                   :master     => @master,
                                   :deployment => @deployment,
                                   :customer   => current_customer,
                                   :muni_admin => current_muni_admin,
                                   :user       => current_user
                               })
    page_error.save
    @network.destroy if @network
    flash[:error] = "Cannot create network."
    logger.detailed_error(boom)
    redirect_to new_master_deployment_network_path(@master, @deployment)
  end

  def update
    @network = Network.find(params[:id])
    if @network && !@network.is_locked?
      authorize_muni_admin!(:edit, @network)

      atts = params[:network].select {|k,v| ["name", "description"].include?(k)}
      @network.update_attributes(atts)
      error = ! @network.save
      if error
        flash[:error] = "Cannot create network."
        render :action => :edit
      else
        flash[:notice] = "Network #{@network.name} has been updated."
        redirect_to master_deployment_network_path(@master, @deployment, @network)
      end
    else
      raise "Argument Error: Network not found or locked."
    end
  rescue Exception => boom
    flash[:error] = "Cannot update network: #{boom}"
    redirect_to master_deployment_network_path(@master, @deployment, @network)
  end

  def copy
    authenticate_muni_admin!
    @network = Network.find(params[:id])

    if @network
      if !@network.is_locked?
        authorize_muni_admin!(:read, @network)

        @deployments   = Deployment.where(:master_id => @master.id).all
        @network_copies   = @network.active_copies.all
        copy_dests        = @network_copies.map { |n| n.deployment }
        route_codes       = []
        @disabled_options = @deployments.map do |muni|
          if copy_dests.include?(muni) || muni.is_active? || @network.deployment == muni
            muni.id
          else
            route_codes += muni.route_codes
            if muni.route_codes.length > 0 &&
                (route_codes - @network.route_codes).length != route_codes.length &&
                muni_admin_can?(:edit, muni)
              muni.id
            else
              nil
            end
          end
        end
        @prompt = "Select Deployment"
        # The copy button is disabled if all options are disabled
        @disabled = @disabled_options.reduce(true) { |t, v| t && v }
        if @disabled
          @prompt = "No eligible deployments"
        end
      else
        flash[:error] = "Network is currently being processed. Must wait for processing to finish."
        redirect_to(:back)
      end
    else
      flash[:error] = "Network is not found."
      redirect_to(:back)
    end
  end

  def copyto
    @network = Network.find(params[:id])
    if params[:dest_network] && params[:dest_network][:deployment]
      dest_deployment = Deployment.find(params[:dest_network][:deployment])
    end
    if dest_deployment.nil?
      raise "Destination Deployment is not found"
    end

    if dest_deployment.is_active?
      flash[:error] = "Cannot copy to an active deployment."
      redirect_to(:back)
      return
    end

    if @network
      if !@network.is_locked?
        authorize_muni_admin!(:read, @network)
        authorize_muni_admin!(:edit, dest_deployment)

        @network_copies = @network.active_copies
        # We have to check that no routes are in the destination.
        route_codes = []
        for n in dest_deployment.networks
          route_codes += n.route_codes
        end
        nrcodes = @network.route_codes
        if route_codes.length > 0 && nrcodes.length > 0 && (route_codes-nrcodes).length < route_codes.length
          raise "Cannot copy the network to the destination due to conflicting routes"
        end

        begin
          network_copy = Network.create_copy(@network, dest_deployment)

          Delayed::Job.enqueue(:queue => @master.slug, :payload_object => CopyNetworkJob.new(@network.id, network_copy.id))

          flash[:notice] = "Network is being copied."
          redirect_to :action => :copy
        rescue Exception => boom
          flash[:error] = "Cannot copy network to selected deployment: #{boom}"
          redirect_to :action => :copy
        end
      else
        flash[:error] = "Network is currently being processed. Must wait for processing to finish."
        redirect_to(:back)
      end

    else
      flash[:error] = "Network is not found."
      redirect_to(:back)
    end
  rescue Exception => boom
    flash[:error] = "Cannot copy network to selected deployment: #{boom}"
    redirect_to :action => :copy
  end

  #
  # This action gets called by a javascript updater on the show page.
  #
  def partial_status
    @network = Network.find(params[:id])

    if @network
      authorize_muni_admin!(:read, @network)
      @last_log = params[:log].to_i if params[:log]
      @limit    = (params[:limit] || 10000000).to_i # makes take(@limit) work if no limit.

      @logs     = @network.copy_log.drop(@last_log).take(@limit) if @last_log

      resp = { :logs => @logs, :last_log => @last_log }

      if (@network.copy_completed_at)
        resp[:completed_at] = @network.copy_completed_at.strftime("%m-%d-%Y %H:%M %Z")
      end
      if (@network.copy_started_at)
        resp[:started_at] = @network.copy_started_at.strftime("%m-%d-%Y %H:%M %Z")
      end
      if (@network.copy_progress)
        resp[:progress] = @network.copy_progress
      end
    else
      resp = {}
    end

    respond_to do |format|
      format.json { render :json => resp.to_json }
    end
  end

  def destroy
    authenticate_muni_admin!
    @network = Network.find(params[:id])
    if @network
      if !@network.is_locked?
        authorize_muni_admin!(:delete, @network)
        name = @network.name
        @network.destroy()
        flash[:notice] = "Network #{name} deleted."
        redirect_to master_deployment_path(@master, @deployment)
      else
        flash[:error] = "Network is currently being processed. Must wait for processing to finish."
        redirect_to(:back)
      end

    else
      flash[:error] = "Network is not found."
      redirect_to(:back)
    end
  end

  def map
    authenticate_muni_admin!
    @network = Network.find(params[:network_id] || params[:id])
    authorize_muni_admin!(:read, @network)
    @network ||= Network.find(params[:id])
    @routes = @network.routes.all.sort { |r1,r2| r1.sort <=> r2.sort }
  end

  def api
    authenticate_muni_admin!
    @network = Network.find(params[:network_id] || params[:id])
    authorize_muni_admin!(:read, @network)
    @network ||= Network.find(params[:id])
    @api = {
        :majorVersion => 1,
        :minorVersion => 0,
        "getRoutePath" => route_master_deployment_network_webmap_path(@master, @deployment, @network),
        "getRouteJourneyIds" => route_journeys_master_deployment_network_webmap_path(@master, @deployment, @network),
        "getRouteDefinition" => routedef_master_deployment_network_webmap_path(@master, @deployment, @network),
        "getJourneyLocation" => curloc_master_deployment_network_webmap_path(@master, @deployment, @network)
    }

    respond_to do |format|
      format.json { render :json => @api }
    end
  end
end
