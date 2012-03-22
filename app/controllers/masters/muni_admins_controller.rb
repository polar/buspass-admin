class Masters::MuniAdminsController < Masters::MasterBaseController
    def index
      @muni_admins = MuniAdmin.where(:master_id => @master.id).all
    end
    def edit
      @muni_admin = MuniAdmin.where(:master_id => @master.id, :id => params[:id]).first
    end
    def show
      @muni_admin = MuniAdmin.where(:master_id => @master.id, :id => params[:id]).first
      @municipalities = Municipality.where(:master_id => @master.id, :owner_id => @muni_admin.id).all
    end
    def update
      @muni_admin = MuniAdmin.where(:master_id => @master.id, :id => params[:id]).first
      params[:muni_admin][:role_symbols] = params[:muni_admin][:roles].select {|x| @muni_admin.possible_roles.include?(x)}
      error = !@muni_admin.update_attributes(params[:muni_admin])
      if error
        render :edit
      else
        redirect_to master_muni_admin_path(@muni_admin, :master_id => @master)
      end

    end
end