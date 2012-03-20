class Muni::Plan::NetworksController < Muni::Plan::ApplicationController

  def index
    authorize!(:read, @master)
    authorize!(:read, @municipality)
    authorize!(:read, Network)
    @networks = Network.all
  end

  def show
    @network = Network.find(params[:id])
    authorize!(:read, @network)
  end

  def new
    authorize!(:create, Network)
    @network = Network.new
    @network = municipality = @muni
  end

  def edit
    authorize!(:edit, Network)
    @network = Network.find(params[:id])
    if @network.municipality != @muni
      raise "Wrong Municipality"
    end
  end

  def create
    authorize!(:create, Network)
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
    authorize!(:edit, @network)
    if @network.municipality != @muni
      raise "Wrong Municipality"
    end
  end

  def destroy
    @network = Network.find(params[:id])
    authorize!(:delete, @network)
    if @network.municipality != @muni
      raise "Wrong Municipality"
    end
    # TODO: Delete files, Services, Routes, VehicleJourneys, JourneyLocations, ReportedJourneyLocations
    @network.destroy
  end
end