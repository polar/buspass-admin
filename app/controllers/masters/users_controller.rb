class Masters::UsersController < Masters::MasterBaseController
  helper_method :sort_column, :sort_direction

  def index
    authorize_muni_admin!(:read, User)

    @roles = User::ROLE_SYMBOLS
    @users = User.where(:master_id => @master.id)
    .search(params[:search])
    .order(sort_column => sort_direction)
    .paginate(:page => params[:page], :per_page => 4)

    respond_to do |format|
      format.html # index.html.erb
      format.json { render :json => @users }
      format.js # render index.js.erb
    end
  end

  def admin
    authorize_muni_admin!(:read, User)

    @roles = User::ROLE_SYMBOLS
    @users = User.where(:master_id => @master.id)
    .search(params[:search])
    .order(sort_column => sort_direction)
    .paginate(:page => params[:page], :per_page => 4)

    respond_to do |format|
      format.html # index.html.erb
      format.json { render :json => @users }
      format.js # render index.js.erb
    end
  end

  def edit
    @user = User.find(params[:id])
    authorize_muni_admin!(:edit, @user)
  end

  def show
    @user = User.find(params[:id])
    authorize_muni_admin!(:read, @user)

    respond_to do |format|
      format.json { render :json => @user }
    end
  end

  def new
    authorize_muni_admin!(:create, User)
    @user = User.new()
    @user.master = @master

    respond_to do |format|
      format.html # new.html.erb
      format.json { render :json => @user }
    end
  end

  def create
    authorize_muni_admin!(:create, User)
    # Security, don't let anything other than these keys get assigned.
    # We don't want some bogon changing the master_id, etc.
    params[:user].slice!(:password, :password_confirmation, :email, :name, :role_symbols)
    @user = User.new(params[:user])
    @user.master = @master

    respond_to do |format|
      if @user.save
        format.html { redirect_to @user, :notice => 'User was successfully created.' }
        format.json { render :json => @user, :status => :created, :location => @user }
      else
        format.html { render :action => "new" }
        format.json { render :json => @user.errors, :status => :unprocessable_entity }
      end
    end
  end


  def update
    attrs = params[:user]
    @user = User.find(params[:id])
    if !@user || @user.master != @master
      raise "Not Found"
    end
    authorize_muni_admin!(:edit, @user)

    @roles = User::ROLE_SYMBOLS

    # Security, don't let anything other than these keys get assigned.
    # We don't want some bogon changing the master_id, etc.
    params[:user].slice!(:password, :password_confirmation, :email, :name, :role_symbols)
    @alt = params[:alt]

    respond_to do |format|
      if @user.update_attributes(params[:user])
        format.html { redirect_to master_users_path(@master), :notice => 'User was successfully updated.' }
        format.json { head :no_content }
        format.js # update.js.erb
      else
        format.html { render :action => "edit" }
        format.json { render :json => @user.errors, :status => :unprocessable_entity }
        format.js # update.js.erb
      end
    end
  end

  def destroy_confirm
    @user = User.find(params[:id])
    authorize_muni_admin!(:delete, @user)
    if @user
      @user.destroy
      redirect_to master_users_path(@master)
    else
      redirect_to master_users_path(@master)
    end
  end

  def destroy
    @user = User.find(params[:id])
    authorize_muni_admin!(:delete, @user)
    @user.destroy

    respond_to do |format|
      format.html { redirect_to master_users_path(@master) }
      format.json { head :no_content }
      format.js # destroy.js.erb
    end
  end

  private

  def sort_column
    User.keys.keys.include?(params[:sort]) ? params[:sort] : "name"
  end

  def sort_direction
    [1, -1].include?(params[:direction].to_i) ? params[:direction].to_i : -1
  end
end