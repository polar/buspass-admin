class MastersController < ApplicationController
  include PageUtils
  layout "empty"

  def authorize_muni_admin!(action, obj)
    raise CanCan::AccessDenied if muni_admin_cannot?(action, obj)
  end

  def activement
    @master = Master.find(params[:id])
    if @master
      @activement = Activement.where(:master_id => @master.id).first
      if @activement
        redirect_to activement_path(@activement)
      else
        render :text => "Deployment's Active Deployment Not Found", :status => 404
      end
    else
      render :text => "Deployment Not Found", :status => 404
    end
  end

  def testament
    @master = Master.find(params[:id])
    if @master
      @testament = Testament.where(:master_id => @master.id).first
      if @testament
        redirect_to master_testament_path(@master, @testament)
      else
        render :text => "Deployment's Testing Deployment Not Found", :status => 404
      end
    else
      render :text => "Deployment Not Found", :status => 404
    end
  end

  def show
    @master = Master.find(params[:id])
    # The DeviseFailureApp needs :master_id
    params[:master_id] = @master.id if @master
    authenticate_muni_admin!
    @activement = Activement.where(:master_id => @master.id).first
    @testament = Testament.where(:master_id => @master.id).first
  end

  def edit
    @master = Master.find(params[:id])
    # The DeviseFailureApp needs :master_id
    params[:master_id] = @master.id if @master
    authenticate_muni_admin!
    authorize_muni_admin!(:edit, @master)
    # submits to update
  end

  MASTER_ALLOWABLE_UPDATE_ATTRIBUTES = [:name, :longitude, :latitude, :timezone]

  def update
    @master = Master.find(params[:id])
    # The DeviseFailureApp needs :master_id
    params[:master_id] = @master.id if @master
    authorize_muni_admin!(:edit, @master)

    # Security Integrity Check.
    master_attributes = params[:master].slice(*MASTER_ALLOWABLE_UPDATE_ATTRIBUTES)
    if master_attributes[:timezone] && master_attributes[:timezone].blank?
      master_attributes.delete(:timezone)
    end
    error = false
    if @master == nil
      flash[:error] = "Master #{params[:id]} doesn't exist"
      error         = true
    else
      slug_was = @master.slug
      success = @master.update_attributes(master_attributes)
      if success
        if slug_was != @master.slug
          @master.admin_site.update_attributes(
              :identifier => "#{@master.slug}-admin",
              :label      => "#{@master.name} Administration Pages",
              :hostname   => "#{@master.slug}.busme.us"
          )
          @master.admin_site.pages.root.update_attributes(
              :label => "#{@master.name} Information"
          )
          @master.main_site.update_attributes(
              :identifier => "#{@master.slug}-main",
              :label      => "#{@master.name} Active Deployment Pages",
              :hostname   => "#{@master.slug}.busme.us"
          )
          @master.main_site.pages.root.update_attributes(
              :label => "#{@master.name} Main Page"
          )
        end

        flash[:notice] = "You have successfully updated your deployment."
      else
        flash[:error] = "You couldn't update your deployment."
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

  def destroy
    authenticate_customer!
    @master = Master.find(params[:id])
    authorize_customer!(:delete, @master)
    @master.destroy
    redirect_to :back
  end

end