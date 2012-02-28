class MunicipalitiesController < ApplicationController

    before_filter :authenticate_admin!, :except => [:index, :show]
    #load_and_authorize_resource

    def authorize!(action, obj)
      raise CanCan::AccessDenied if admin_cannot?(action, obj)
    end

    def index
        if admin_signed_in?
            @munis = case params[:purpose]
                when "edit" then Municipality.editable_by(current_admin)
                when "read" then Municipality.readable_by(current_admin)
                else Municipality.all()
            end
        else
            @munis = Municipality.all
        end
    end

    def show
        @muni = Municipality.find(params[:id])
        authorize!(:show, @muni)
    end

    def new
        authorize!(:create, Municipality)
        @muni = Municipality.new
        # submits to create
    end

    def edit
        @muni = Municipality.find(params[:id])
        authorize!(:edit, @muni)
        # submits to update
    end

    def create
        error = false
        puts ("ADMIN #{current_admin}")
        authorize!(:create, Municipality)
        location = params[:municipality][:location]
        if location != nil
            params[:municipality][:location] = view_context.from_location_str(location)
        end
        @muni       = Municipality.new(params[:municipality])
        @muni.owner = current_admin
        error       = !@muni.save
        if !error
            flash[:notice] = "You have successfully created your municipality."
        else
            flash[:error] = "You couldn't create your municipality."
        end
        if !error
            # create the new database
            @dbname = "#Busme-#{Rails.env}-#{@muni.slug}"
            logger.info("Creating New Municipality Database #{@dbname}")
            MongoMapper.database = @dbname
            @muni                = Municipality.new(@muni.attributes)
            @muni.owner          = nil                      # Owner is not relevant in new database.
            @muni_admin          = MuniAdmin.new(current_admin.attributes.slice("encrypted_password", "email", "name"))
            @muni_admin.disable_empty_password_validation() # Keeps from arguing for a non-empty password.
            @muni_admin.add_roles([:super,:planner,:operator])
            @muni_admin.save!
            @muni.save!
        end

        respond_to do |format|
            format.html {
                if error
                    render :new
                else
                    redirect_to municipality_path(@muni)
                end
            }
            format.all do
                method = "to_#{request_format}"
                text   = { }.respond_to?(method) ? { }.send(method) : ""
                render :text => text, :status => :ok
            end
        end
    end

    def update
        @muni = Municipality.find(params[:id])
        authorize!(:edit, @muni)

        location = params[:municipality][:location]
        if location != nil
            params[:municipality][:location] = view_context.from_location_str(location)
        end
        error = false
        if @muni == nil
            flash[:error] = "Municipality #{params[:id]} doesn't exist"
            error         = true
        elsif @muni.owner != current_admin
            @muni.errors.add_to_base("You do not have permission to update this object")
            flash[:error] = "You do not have permission to update this object"
            error         = true
        else
            @muni.update_attributes(params[:municipality])
            error = !@muni.save
            if !error
                flash[:notice] = "You have successfully updated your municipality."
            else
                flash[:error] = "You couldn't update your municipality."
            end
        end
        respond_to do |format|
            format.html {
                if error
                    render :edit
                else
                    redirect_to municipality_path(@muni)
                end
            }
            format.all do
                method = "to_#{request_format}"
                text   = { }.respond_to?(method) ? { }.send(method) : ""
                render :text => text, :status => :ok
            end
        end
    end

    def delete
        @muni = Municipality.find(params[:id])
        authorize!(:delete, @muni)

        if @muni == nil
            flash[:error] = "Municipality #{params[:id]} doesn't exist"
            error = true
        elsif @muni.owner != current_admin
            @muni.errors.add_to_base("You do not have permission to delete this object")
            error = true
        else
            @muni.delete()
        end
        respond_to do |format|
            format.html {
                redirect_to municipalities_path
            }
            format.all do
                method = "to_#{request_format}"
                text = {}.respond_to?(method) ? {}.send(method) : ""
                render :text => text, :status => :ok
            end
        end
    end

end