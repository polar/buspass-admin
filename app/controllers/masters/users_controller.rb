class Masters::UsersController < Masters::MasterBaseController
  helper_method :sort_column, :sort_direction

  def index
    get_master_context
    authorize_muni_admin!(:read, User)

    @roles = User::ROLE_SYMBOLS
    @users = User.where(:master_id => @master.id)
    .search(params[:search])
    .order(sort_column => sort_direction)
    .paginate(:page => params[:page], :per_page => 20)

    respond_to do |format|
      format.html # index.html.erb
      format.json { render :json => @muni_admins }
      format.js # render index.js.erb
    end
  end

  def new
    get_master_context
    authorize_muni_admin!(:create, User)
    @user = User.new()
    @user.master = @master

    respond_to do |format|
      format.html # new.html.erb
      format.json { render :json => @user }
    end
  end

  #
  # This action is currently called as JS from the users/admin window.
  #
  def update
    get_master_context
    @user = User.find(params[:id])
    if @user.nil? || @user.master != @master
      raise NotFoundError.new("User #{params[:id]} not found")
    end
    authorize_muni_admin!(:edit, @user)

    @roles = User::ROLE_SYMBOLS

    # Security, don't let anything other than these keys get assigned.
    # We don't want some bogon changing the master_id, etc.
    params[:user].slice!(:email, :name, :role_symbols)
    @alt = params[:alt]

    @user.update_attributes(params[:user])
  end

  # The destroy operation is only called as JS from the users/admin page
  def destroy
    get_master_context
    @user = User.find(params[:id])
    authorize_muni_admin!(:delete, @user)
    if @user
      @user.destroy
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