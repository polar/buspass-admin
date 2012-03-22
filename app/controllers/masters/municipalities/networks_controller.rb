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
    authorize!(:read, @network)
  end

  def create
    authorize!(:create, Network)
    @network = Network.new(params[:network])
    @network.owner = current_muni_admin
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
end
