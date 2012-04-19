class Masters::UserController < Masters::MasterBaseController
  def index
    @users = User.where(:master_id => @master.id).all
  end
  def edit
    @user = User.where(:master_id => @master.id, :id => params[:id]).first
  end
  def show
    @user = User.where(:master_id => @master.id, :id => params[:id]).first
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