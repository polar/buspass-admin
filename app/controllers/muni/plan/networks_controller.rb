class Muni::Plan::NetworksController < Muni::ApplicationController

  before_filter :authenticate_muni_admin!

  def authorize!(action, obj)
    p self.methods
    p current_user_ability(:muni_admin)
    # Looks like muni_admin_can?  is not generated.
    raise CanCan::AccessDenied if current_user_ability(:muni_admin).cannot?(action, obj)
  end
  
  def index
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
  end

  def edit
    authorize!(:edit, Network)
    @network = Network.find(params[:id])
  end

  def create
    authorize!(:create, Network)
    @network = Network.new(params[:network])
    @network.mode = :planning
    error = !@network.save
    respond_to do |format|
      format.html {
        if error
          flash[:error] = "cannot create network"
          render :new
        else
          flash[:notice] = "Network #{@network.name} has been created"
          redirect_to(plan_network_path(@network, :muni => @muni.slug))
        end
      }
    end
  end

  def update
    @network = Network.find(params[:id])
    authorize!(:edit, @network)
  end

  def destroy
    @network = Network.find(params[:id])
    authorize!(:delete, @network)
  end
end