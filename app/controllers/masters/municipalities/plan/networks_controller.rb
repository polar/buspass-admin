class Masters::Municipalities::Plan::NetworksController < Masters::Municipalities::Plan::ApplicationController

  def index
    authorize_muni_admin!(:read, @master)
    authorize_muni_admin!(:read, @municipality)
    authorize_muni_admin!(:read, Network)
    @networks = Network.all
  end

  def show
    @network = Network.find(params[:id])
    authorize_muni_admin!(:read, @network)
  end

  def new
    authorize_muni_admin!(:create, Network)
    @network = Network.new
    @network = municipality = @muni
  end

  def edit
    authorize_muni_admin!(:edit, Network)
    @network = Network.find(params[:id])
    if @network.municipality != @muni
      raise "Wrong Municipality"
    end
  end

  def create
    authorize_muni_admin!(:create, Network)
    @network = Network.new(params[:network])
    @network.mode = :planning
    @network.municipality = @muni
    error = !@network.save
    respond_to do |format|
      format.html {
        if error
          flash[:error] = "cannot create network"
          render :new
        else
          flash[:notice] = "Network #{@network.name} has been created"
          redirect_to(plan_network_path(@network, :masters => @muni.slug))
        end
      }
    end
  end

  def update
    @network = Network.find(params[:id])
    authorize_muni_admin!(:edit, @network)
    if @network.municipality != @muni
      raise "Wrong Municipality"
    end
  end

  def destroy
    @network = Network.find(params[:id])
    authorize_muni_admin!(:delete, @network)
    if @network.municipality != @muni
      raise "Wrong Municipality"
    end
    # TODO: Delete files, Services, Routes, VehicleJourneys, JourneyLocations, ReportedJourneyLocations
    @network.destroy
  end
end