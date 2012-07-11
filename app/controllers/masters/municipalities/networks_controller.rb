class Masters::Municipalities::NetworksController < Masters::Municipalities::MunicipalityBaseController
  include PageUtils

  def index
    @networks = Network.where(:municipality_id => @municipality.id).all
  end

  def new
    authorize_muni_admin!(:create, Network)
    @network = Network.new
  end

  def show
    @network = Network.find(params[:id])
    authorize_muni_admin!(:read, @network)
  end

  def edit
    @network = Network.find(params[:id])
    authorize_muni_admin!(:edit, @network)
  end

  NETWORK_UPDATE_ALLOW_ATTRIBUTES = [:name, :description]

  def create
    authorize_muni_admin!(:create, Network)

    network_attributes = params[:network].merge(*NETWORK_UPDATE_ALLOW_ATTRIBUTES)

    @network = Network.new(network_attributes)
    @network.municipality = @municipality
    @network.master = @master
    error = ! @network.save
    if error
      flash[:error] = "Cannot create network."
      render :action => :new
    else
      create_master_deployment_network_page(@master, @municipality, @network)

      flash[:notice] = "Network #{@network.name} has been created."
      redirect_to master_municipality_network_path(@master, @municipality, @network)
    end
  rescue Exception => boom
    @network.destroy if @network
    flash[:error] = "Cannot create network."
    redirect_to new_master_municipality_network_path(@master, @municipality)
  end

  def update
    @network = Network.find(params[:id])
    if @network.nil?
      raise "Argument Error: Network not found"
    end
    authorize_muni_admin!(:edit, @network)

    atts = params[:network].select {|k,v| ["name", "description"].include?(k)}
    @network.update_attributes(atts)
    error = ! @network.save
    if error
      flash[:error] = "Cannot create network."
      render :action => :edit
    else
      flash[:notice] = "Network #{@network.name} has been updated."
      redirect_to master_municipality_network_path(@master, @municipality, @network)
    end
  rescue Exception => boom
    flash[:error] = "Cannot update network: #{boom}"
    redirect_to master_municipality_network_path(@master, @municipality, @network)
  end

  def copy
    @network = Network.find(params[:id])
    authorize_muni_admin!(:read, @network)

    @municipalities   = Municipality.where(:master_id => @master.id).all
    @network_copies   = @network.active_copies.all
    copy_dests        = @network_copies.map { |n| n.municipality }
    route_codes       = []
    @disabled_options = @municipalities.map do |muni|
      if copy_dests.include?(muni)
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
    # The copy button is disabled if all options are disabled
    @disabled = @disabled_options.reduce(true) { |t, v| t && v }
  end

  def copyto
    @network = Network.find(params[:id])
    if params[:network] && params[:network][:municipality]
      dest_municipality = Municipality.find(params[:network][:municipality])
    end
    if dest_municipality.nil?
      raise "Destination Municipality not found"
    end
    authorize_muni_admin!(:read, @network)
    authorize_muni_admin!(:edit, dest_municipality)

    @network_copies = @network.active_copies
    # We have to check that no routes are in the destination.
    route_codes = []
    for n in dest_municipality.networks
      route_codes += n.route_codes
    end
    nrcodes = @network.route_codes
    if route_codes.length > 0 && nrcodes.length > 0 && (route_codes-nrcodes).length < route_codes.length
      raise "Cannot copy the network to the destination due to conflicting routes"
    end

    begin
      network_copy = Network.create_copy(@network, dest_municipality)

      Delayed::Job.enqueue(:payload_object => CopyNetworkJob.new(@network.id, network_copy.id))

      flash[:notice] = "Network is being copied."
      redirect_to :action => :copy
    rescue Exception => boom
      flash[:error] = "Cannot copy network to selected deployment: #{boom}"
      redirect_to :action => :copy
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

      resp = { :logs => @logs }

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
    @network = Network.find(params[:id])
    if @network
      authorize_muni_admin!(:delete, @network)
      name = @network.name
      @network.destroy()
      flash[:notice] = "Network #{name} deleted."
    else
    end

    redirect_to master_municipality_path(@master, @municipality)
  end
end
