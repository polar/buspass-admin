class Masters::MuniAdminsController < Masters::MasterBaseController
    def index
      authorize!(:read, MuniAdmin)
      @muni_admins = MuniAdmin.where(:master_id => @master.id).all
    end

    def edit
      @muni_admin = MuniAdmin.where(:master_id => @master.id, :id => params[:id]).first
      authorize!(:edit, @muni_admin)
    end

    def show
      @muni_admin = MuniAdmin.where(:master_id => @master.id, :id => params[:id]).first
      authorize!(:read, @muni_admin)
      @municipalities = Municipality.where(:master_id => @master.id, :owner_id => @muni_admin.id).all
    end

    def new
      authorize!(:create, MuniAdmin)
      @muni_admin = MuniAdmin.new()
    end

    def create
      authorize!(:create, MuniAdmin)
      params[:muni_admin][:master_id] = @master.id

      params[:muni_admin][:role_symbols] = params[:muni_admin][:roles].select {|x| @muni_admin.possible_roles.include?(x)}
      @muni_admin = MuniAdmin.new(params[:muni_admin])

      if @muni_admin.save
        redirect_to :index, :master_id => @master.id
      else
        render :new
      end

    end

    def update
      attrs = params[:muni_admin]
      @muni_admin = MuniAdmin.find(params[:id])
      if !@muni_admin
        raise "Not Found"
      end
      authorize!(:edit, @muni_admin)

      if attrs[:password].empty?
        attrs.reject! {|k| [:password, :password_confirmation].include?(k) }
        @muni_admin.disable_empty_password_validation
      end

      attrs[:role_symbols] = attrs[:roles].select {|x| @muni_admin.possible_roles.include?(x)}
      if @muni_admin == current_muni_admin && !attrs[:role_symbols].include?("super")
        @muni_admin.errors[:base] << "You have the role of Super. You cannot remove that role from yourself."
        error = true;
      end
      error = error || !@muni_admin.update_attributes(params[:muni_admin])
      if error
        render :edit
      else
        @muni_admin.save
        redirect_to master_muni_admin_path(@muni_admin, :master_id => @master)
      end

    end

    def destroy_confirm
      @muni_admin = MuniAdmin.find(params[:id])
      authorize!(:delete, @muni_admin)
      if @muni_admin
        @masters = Master.where(:owner_id => @muni_admin.id).all
        @municipalities = Municipality.where(:owner_id => @muni_admin.id).all
        if @masters.empty? && @municipalities.empty?
          @muni_admin.destroy
          redirect_to master_muni_admin_path(:master_id => @master.id)
        else
        end
      else
        redirect_to master_muni_admin_path(:master_id => @master.id)
      end
    end

    def destroy
      @muni_admin = MuniAdmin.find(params[:id])
      authorize!(:delete, @muni_admin)
      if @muni_admin
        @masters = Master.where(:owner_id => @muni_admin.id).all
        @municipalities = Municipality.where(:owner_id => @muni_admin.id).all

        @masters.each {|x| x.owner = current_muni_admin; x.save }
        @municipalities.each {|x| x.owner = current_muni_admin; x.save }
        @muni_admin.destroy
      end
      redirect_to master_muni_admin_path(:master_id => @master.id)
    end
end