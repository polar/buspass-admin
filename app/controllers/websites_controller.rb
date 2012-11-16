##
# Controller for Toplevel Master Deployment Websites.
# A "Website" is synonymous with the Master and CMS::Site combination.
#
class WebsitesController < ApplicationController
  include PageUtils
  layout "empty"

  def index
    if current_customer
      @masters = case params[:purpose]
        when "edit" then
          Master.editable_by(current_customer)
        when "read" then
          Master.readable_by(current_customer)
        else
          Master.all()
      end
    else
      @masters = Master.all
    end
    @site = get_front_site()
  end

  def admin
    authenticate_customer!
    authorize_customer!(:edit, Cms::Site)
    @masters = Master.all
    @site = get_front_site()
  end

  def my_index
    authenticate_customer!
    @masters = Master.owned_by(current_customer).all
    @site = get_front_site()
  end

  def show
    authenticate_customer!
    @master = Master.find(params[:id])
    authorize_customer!(:read, Master)
    @site = Cms::Site.find_by_identifier("busme-main")
  end

  def new
    authenticate_customer!
    authorize_customer!(:create, Master)
    @master = Master.new
    @site = get_front_site()
    # submits to create
  end

  def edit
    authenticate_customer!
    @master = Master.find(params[:id])
    @site = get_front_site()
    authorize_customer!(:edit, @master)
    # submits to update
  end

  MASTER_ALLOWABLE_UPDATE_ATTRIBUTES = [:name, :longitude, :latitude, :timezone, :slug]

  def s3_bucket
    s3 = AWS::S3.new(
         :access_key_id => ENV['AWS_ACCESS_KEY_ID'],
         :secret_access_key => ENV['AWS_SECRET_ACCESS_KEY'])
    s3.buckets[ENV['S3_BUCKET_NAME']]
  end

  def create
    authorize_customer!(:create, Master)

    @site = get_front_site()

    # Security Integrity Check, ignoring any unwanted inserted attributes
    master_attributes = params[:master].slice(*MASTER_ALLOWABLE_UPDATE_ATTRIBUTES)

    local_master  = nil
    @master       = Master.new(master_attributes)
    @master.owner = current_customer

    # TODO: These dbnames really should be GUIDs, but for Development.
    if Rails.env == "development"
      @master.ensure_slug()
      dbname = "#Busme-#{Rails.env}-#{@master.slug}"
    else
      # We use the id of the MasterDeployment for a unique name.
      dbname = "#Busme-#{Rails.env}-#{@master.id.to_s}"
    end

    # Currently not used until we start shifting masters to their own databases.
    @master.dbname = dbname
    @master.save!

    @s3_bucket = s3_bucket()

    # Creating the modifiable administrator pages for the Master.
    @admin_site = create_master_admin_site(@master, @s3_bucket)
    @main_site  = create_master_main_site(@master, @s3_bucket)

    logger.info("Creating New Deployment Database #{dbname} for Master #{@master.name}")

    master         = @master
                                   # Save everything to the new database, which is the local masterdb.
    local_masterdb = dbname

=begin
      # We need to save again, but in the new database, as a place holder and default information.
      # We will have to save customer(s)) as well.
      Master.set_database_name(local_masterdb)

      local_master        = Master.new(master_attributes)
      local_master.owner  = nil # This has no relevance since it may be in a different site.
      local_master.dbname = local_masterdb
      local_master.save!

      # Master Deployment and MuniAdmins are in the "masters" database
      # for the whole masters Deployment. This DB will contain the
      # MuniAdmin, the GoogleUriViewPath cache, and the Deployments in
=end
    local_master          = master # their various modes and deployments.

    #MuniAdmin.set_database_name(local_masterdb)

    muni_admin_attributes = current_customer.attributes.slice("email", "name")
    @muni_admin           = MuniAdmin.new(muni_admin_attributes)
    @muni_admin.master    = local_master
    auths = current_customer.authentications_copy(:master_id => local_master.id)
    auths.each{ |auth| @muni_admin.authentications << auth }
    @muni_admin.add_roles([:super, :planner, :operator])
    @muni_admin.save!

    # Creating the first Deployment, which is a courtesy.
    @deployment              = Deployment.new()
    @deployment.name         = "Deployment 1"
    @deployment.display_name = "Deployment 1"
    @deployment.latitude     = local_master.latitude
    @deployment.longitude    = local_master.longitude
    @deployment.owner        = @muni_admin
    @deployment.master       = local_master
    @deployment.save!
    create_master_deployment_page(@master, @deployment)

    # Creating the first Network in the first Deployment, which is a courtesy.
    @network              = Network.new
    @network.master       = @master
    @network.deployment = @deployment
    @network.name         = "Network 1"
    @network.ensure_slug
    @network.save!
    create_master_deployment_network_page(@master, @deployment, @network)

    flash[:notice] = "Site #{master.name} created with default deployment and default network"

    if current_customer.has_role?(:admin) || current_customer.has_role?(:super)
      redirect_to my_index_websites_path
    else
      # We are going to switch from the Customer site to the Master site
      @customer = current_customer
      @old_auth = current_authentication
      sign_out(current_customer)
      # We have copied over all the authentications to the MuniAdmin
      # We will just say that he is still authenticated with the one from the
      # same provider, since we only allow one from each.
      sign_in(@muni_admin, @muni_admin.authentications.find_by_provider(@old_auth.provider))
      redirect_to master_path(@master)
    end

  rescue Exception => boom
    Rails.logger.detailed_error(boom)
    @admin_site.destroy if @admin_site
    @main_site.destroy if @main_site
    @master.destroy if @master
    @deployment.destroy if @deployment
    @muni_admin.destroy if @muni_admin
    if @customer
      sign_in(@customer, @old_auth)
    end

    flash[:error] = "Could not create the site for your deployment."
    @render_action = "new"  # This is needed for the layout.
    render :action => :new
  end

  def update
    @master = Master.find(params[:id])
    @site = get_front_site()

    authorize_customer!(:edit, @master)

    # Security Integrity Check, ignoring any unwanted inserted attributes
    master_attributes = params[:master].slice(*MASTER_ALLOWABLE_UPDATE_ATTRIBUTES)

    error = false
    if @master == nil
      flash[:error] = "Master Deployment #{params[:id]} doesn't exist"
      error         = true
    elsif customer_cannot?(:edit, @master)
      flash[:error] = "You do not have permission to update this object"
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
          redirect_to websites_path
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
    @master = Master.find(params[:id])
    @site = get_front_site()

    authorize_customer!(:delete, @master)

    if @master == nil
      flash[:error] = "Deployment #{params[:id]} doesn't exist"
      error         = true
    elsif customer_cannot?(:delete, @master)
      flash[:error] = "You do not have permission to delete the #{@master.name} Deployment."
      error = true
    else
      @master.destroy()
    end
    respond_to do |format|
      format.html {
        redirect_to websites_path
      }
      format.all do
        method = "to_#{request_format}"
        text   = { }.respond_to?(method) ? { }.send(method) : ""
        render :text => text, :status => :ok
      end
    end
  end

  private

  def get_front_site
    Cms::Site.find_by_identifier("busme-main")
  end
end