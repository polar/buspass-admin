class MuniAdminsController < ApplicationController
  helper_method :sort_column, :sort_direction

  def authorize_muni_admin!(action, obj)
    raise CanCan::AccessDenied if muni_admin_cannot?(action, obj)
  end

  def index
    @roles = muni_admin::ROLE_SYMBOLS
    params[:search] = params[:search].merge({ :master_id => @master.id })
    @muni_admins = muni_admin.search(params[:search]).order(sort_column => sort_direction).paginate(:page => params[:page], :per_page => 4)

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @muni_admins }
      format.js # render index.js.erb
    end
  end

  def admin
    @roles = muni_admin::ROLE_SYMBOLS
    params[:search] = params[:search].merge({ :master_id => @master.id })
    @muni_admins = muni_admin.search(params[:search]).order(sort_column => sort_direction).paginate(:page => params[:page], :per_page => 4)

    respond_to do |format|
      format.html # admin.html.erb
      format.json { render json: @muni_admins }
      format.js # render admin.js.erb
    end
  end

  def show
    @muni_admin = muni_admin.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @muni_admin }
    end
  end

  def new
    @muni_admin = muni_admin.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @muni_admin }
    end
  end

  def edit
    @muni_admin = muni_admin.find(params[:id])
  end

  def create
    @muni_admin = muni_admin.new(params[:muni_admin])
    @muni_admin.master = @master

    respond_to do |format|
      if @muni_admin.save
        format.html { redirect_to @muni_admin, notice: 'muni_admin was successfully created.' }
        format.json { render json: @muni_admin, status: :created, location: @muni_admin }
      else
        format.html { render action: "new" }
        format.json { render json: @muni_admin.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    @roles = muni_admin::ROLE_SYMBOLS
    @muni_admin = muni_admin.find(params[:id])
    @muni_admin.master = @master

    if current_muni_admin == @muni_admin
      # We don't want you to alter your own roles.
      params[:muni_admin][:role_symbols] = @muni_admin.role_symbols
    end

    respond_to do |format|
      if @muni_admin.update_attributes(params[:muni_admin])
        format.html { redirect_to @muni_admin, notice: 'muni_admin was successfully updated.' }
        format.json { head :no_content }
        format.js # update.js.erb
      else
        format.html { render action: "edit" }
        format.json { render json: @muni_admin.errors, status: :unprocessable_entity }
        format.js # update.js.erb
      end
    end
  end

  def destroy
    @muni_admin = muni_admin.find(params[:id])
    @muni_admin.destroy

    respond_to do |format|
      format.html { redirect_to muni_admins_url }
      format.json { head :no_content }
      format.js # destroy.htm.erb
    end
  end

  # TODO This controller should go in Masters.

  private

  def sort_column
    muni_admin.keys.keys.include?(params[:sort]) ? params[:sort] : "name"
  end

  def sort_direction
    [1, -1].include?(params[:direction].to_i) ? params[:direction].to_i : -1
  end
end
