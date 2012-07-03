class MastersController < ApplicationController
  include PageUtils
  layout "empty"

  def authorize_muni_admin!(action, obj)
    raise CanCan::AccessDenied if muni_admin_cannot?(action, obj)
  end

  def deployment
    @master = Master.find(params[:id])
    if @master
      @deployment = Deployment.where(:master_id => @master.id).first
      if @deployment
        redirect_to deployment_path(@deployment)
      else
        render :text => "Municipality's Active Deployment Not Found", :status => 404
      end
    else
      render :text => "Municipality Not Found", :status => 404
    end
  end

  def testament
    @master = Master.find(params[:id])
    if @master
      @testament = Testament.where(:master_id => @master.id).first
      if @testament
        redirect_to testament_path(@testament)
      else
        render :text => "Municipality's Testing Deployment Not Found", :status => 404
      end
    else
      render :text => "Municipality Not Found", :status => 404
    end
  end

  def show
    authenticate_muni_admin!
    @master = Master.find(params[:id])
    if @master.nil?
      raise "Not found"
    end
    @deployment = Deployment.where(:master_id => @master.id).first
    @testament = Testament.where(:master_id => @master.id).first
  end

  def edit
    authenticate_muni_admin!
    @master = Master.find(params[:id])
    authorize_muni_admin!(:edit, @master)
    # submits to update
  end

  def update
    authenticate_muni_admin!
    @master = Master.find(params[:id])
    authorize_muni_admin!(:edit, @master)

    location = params[:master][:location]
    if location != nil
      params[:master][:location] = view_context.from_location_str(location)
    end
    error = false
    if @master == nil
      flash[:error] = "Master Municipality #{params[:id]} doesn't exist"
      error         = true
    elsif @master.owner != current_customer
      @master.errors.add_to_base("You do not have permission to update this object")
      flash[:error] = "You do not have permission to update this object"
      error         = true
    else
      @master.update_attributes(params[:master])
      error = !@master.save
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
          redirect_to master_path(@master)
        end
      }
      format.all do
        method = "to_#{request_format}"
        text   = { }.respond_to?(method) ? { }.send(method) : ""
        render :text => text, :status => :ok
      end
    end
  end

end