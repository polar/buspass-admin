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
    @network = Network.where(:master_id => @master.id, :municipality_id => @municipality.id, :id => params[:id]).first
    if @network.nil?
      raise "Network not found"
    end
    authorize_muni_admin!(:edit, @network)
  end

  def create
    authorize_muni_admin!(:create, Network)
    @network = Network.new(params[:network])
    @network.municipality = @municipality
    @network.master = @master
    error = ! @network.save
    if error
      flash[:error] = "Cannot create network."
      render :new
    else
      create_master_deployment_network_page(@master, @municipality, @network)

      flash[:notice] = "Network #{@network.name} has been created."
      redirect_to master_municipality_network_path(@master, @municipality, @network)
    end
  rescue Exception => boom
    @network.destroy if @network
  end

  def update
    @network = Network.where(:master_id => @master.id, :municipality_id => @municipality.id, :id => params[:id]).first
    if @network.nil?
      raise "Network not found"
    end
    authorize_muni_admin!(:edit, @network)
    atts = params[:network].select {|k,v| ["name", "description"].include?(k)}
    @network.update_attributes(atts)
    error = ! @network.save
    if error
      flash[:error] = "Cannot create network."
      render :edit
    else
      flash[:notice] = "Network #{@network.name} has been updated."
      redirect_to master_municipality_network_path(@master, @municipality, @network)
    end
  end

  def copy
    @network = Network.find(params[:id])
    authorize_muni_admin!(:read, @network)
    set_copy_view_variables
  end

  def set_copy_view_variables
    @municipalities   = Municipality.where(:master_id => @master.id).all
    route_codes       = []
    @disabled_options = @municipalities.map do |muni|
      route_codes += muni.route_codes
      if muni.route_codes.length > 0 &&
          (route_codes - @network.route_codes).length != route_codes.length &&
          muni_admin_can?(:edit, muni)
        muni.id
      else
        nil
      end
    end
    @network_copy = @network.copy_to
    # The copy button is disabled if all options are disabled
    @disabled = @network_copy || @disabled_options.reduce(true) { |t,v| t && v }
  end

  def copyto
    @network = Network.find(params[:id])
    if params[:network] && params[:network][:municipality]
      @dest_municipality = Municipality.find(params[:network][:municipality])
    end
    if @dest_municipality.nil?
      raise "Destination Municipality not found"
    end
    authorize_muni_admin!(:read, @network)
    authorize_muni_admin!(:edit, @dest_municipality)

    @network_copy = @network.copy_to
    if @network_copy
      raise "Cannot copy the network, it is locked already being copied."
    end
    # We have to check that no routes are in the destination.
    route_codes = []
    for n in @dest_municipality.networks
      route_codes += n.route_codes
    end
    nrcodes = @network.route_codes
    if route_codes.length > 0 && nrcodes.length > 0 && (route_codes-nrcodes).length < route_codes.length
      raise "Cannot copy the network to the destination due to conflicting routes"
    end

    begin
      @network_copy = Network.create_copy(@network, @dest_municipality)

      Delayed::Job.enqueue(:payload_object => CopyNetworkJob.new(@network.id, @network_copy.id))

      flash[:notice] = "Network is being copied."
      set_copy_view_variables
      render :copy
    rescue Exception => boom
      flash[:error] = "Cannot copy network to selected deployment: #{boom}"
      set_copy_view_variables
      render :copy
    end
  rescue Exception => boom
    flash[:error] = "Cannot copy network to selected deployment: #{boom}"
    set_copy_view_variables
    render :copy
  end
  #
  # This action gets called by a javascript updater on the show page.
  #
  def partial_status
    @network = Network.find(params[:id])
    authorize_muni_admin!(:read, @network)
    @network_copy = @network.copy_to

    if @network_copy
      @last_log = params[:log].to_i
      @last_err = params[:err].to_i
      @limit    = (params[:limit] || 10000000).to_i # makes take(@limit) work if no limit.

      @errors = @network_copy.copy_errors.drop(@last_err).take(@limit)
      @logs   = @network_copy.copy_log.drop(@last_log).take(@limit)

      resp = { :errors => @errors, :logs => @logs }

      if (@network_copy.copy_completed_at)
        resp[:completed_at] = @network_copy.copy_completed_at.strftime("%m-%d-%Y %H:%M %Z")
      end
      if (@network_copy.copy_started_at)
        resp[:started_at] = @network_copy.copy_started_at.strftime("%m-%d-%Y %H:%M %Z")
      end
      if (@network_copy.copy_progress)
        resp[:progress] = @network_copy.copy_progress
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
