class Masters::UsersController < Masters::MasterBaseController
  layout "masters/normal-layout"
  def index
    @users = User.where(:master_id => @master.id).all
  end
  def admin
    @users = User.where(:master_id => @master.id).all
    render :action => :index
  end
  def edit
    @user = User.where(:master_id => @master.id, :id => params[:id]).first
  end
  def show
    @user = User.where(:master_id => @master.id, :id => params[:id]).first
  end

  def new
    authorize!(:create, User)
    @user = User.new()
  end

  def create
    authorize!(:create, User)
    params[:user][:master_id] = @master.id

    params[:user][:role_symbols] = params[:user][:roles].select {|x| user.possible_roles.include?(x)}
    @user = User.new(params[:user])

    if @user.save
      redirect_to :index, :master_id => @master.id
    else
      render :new
    end

  end

  def update
    @user = User.where(:master_id => @master.id, :id => params[:id]).first
    params[:user][:role_symbols] = params[:user][:roles].select {|x| @user.possible_roles.include?(x)}
    error = !@user.update_attributes(params[:user])
    if error
      render :edit
    else
      redirect_to master_home_path(:master_id => @master.id)
    end

  end
end