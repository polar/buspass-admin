class Masters::Municipalities::NetworksController < Masters::Municipalities::MunicipalityBaseController
  def index
    @networks = Network.where(:municipality_id => @municipality.id).all
  end

  def new
    authorize!(:create, Network)
    @network = Network.new
  end

  def show
    @network = Network.where(:master_id => @master.id, :municipality_id => @municipality.id, :id => params[:id]).first
    if @network.nil?
      raise "Network not found"
    end
    authorize!(:read, @network)
  end

  def edit
    @network = Network.where(:master_id => @master.id, :municipality_id => @municipality.id, :id => params[:id]).first
    if @network.nil?
      raise "Network not found"
    end
    authorize!(:edit, @network)
  end

  def create
    authorize!(:create, Network)
    @network = Network.new(params[:network])
    @network.municipality = @municipality
    @network.master = @master
    error = ! @network.save
    if error
      flash[:error] = "Cannot create network."
      render :new
    else
      flash[:notice] = "Network #{@network.name} has been created."
      redirect_to master_municipality_network_path(@network, :master_id => @master.id, :municipality_id => @municipality.id)
    end
  end

  def update
    @network = Network.where(:master_id => @master.id, :municipality_id => @municipality.id, :id => params[:id]).first
    if @network.nil?
      raise "Network not found"
    end
    authorize!(:edit, @network)
    atts = params[:network].select {|k,v| ["name", "description"].include?(k)}
    @network.update_attributes(atts)
    error = ! @network.save
    if error
      flash[:error] = "Cannot create network."
      render :edit
    else
      flash[:notice] = "Network #{@network.name} has been updated."
      redirect_to master_municipality_network_path(@network, :master_id => @master.id, :municipality_id => @municipality.id)
    end
  end


  def move
    @network = Network.where(:master_id => @master.id, :municipality_id => @municipality.id, :id => params[:id]).first
    if @network.nil?
      raise "Network not found"
    end
    authorize!(:read, @network)

    @municipalities = Municipality.where(:master_id => @master.id).all
    route_codes = []
    @disabled_options = @municipalities.map do |muni|
      route_codes += muni.route_codes
      muni.id if muni.route_codes.length > 0 && (route_codes - @network.route_codes).length != route_codes.length
    end

  end

  def moveto
    @network = Network.where(:master_id => @master.id, :municipality_id => @municipality.id, :id => params[:id]).first
    if @network.nil?
      raise "Network not found"
    end
    if params[:network] && params[:network][:municipality]
      @dest_municipality = Municipality.where(:master_id => @master.id, :id => params[:network][:municipality]).first
      end
    if @dest_municipality.nil?
      raise "Destination Municipality not found"
    end
    authorize!(:read, @network)
    authorize!(:edit, @dest_municipality)

    # We have to check that no routes are in the destination.
    route_codes = []
    for n in @dest_municipality.networks
      route_codes += n.route_codes
    end
    nrcodes = @network.route_codes
    if route_codes.length > 0 && nrcodes.length > 0 && (route_codes-nrcodes).length < route_codes.length
      raise "Cannot move the network to the destination due to conflicting routes"
    end

    @new_network = nil
    begin
      @new_network = @network.copy!(@dest_municipality)
      redirect_to master_municipality_path(@dest_municipality, :master_id => @master.id)
    rescue
      flash[:error] = "Cannot copy network to selected deployment because of conflict with route codes or names"
      render :show
    end
  end

  def destroy
    @network = Network.where(:master_id => @master.id, :municipality_id => @municipality.id, :id => params[:id]).first
    authorize!(:delete, @network)
    @network.destroy()
    redirect_to master_municipality_path(@municipality, :master_id => @master.id)
  end
end
