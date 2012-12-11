class CreateSiteJob < Struct.new(:customer_id, :master_id)
  include PageUtils

  def s3_bucket
    s3 = AWS::S3.new(
        :access_key_id => ENV['AWS_ACCESS_KEY_ID'],
        :secret_access_key => ENV['AWS_SECRET_ACCESS_KEY'])
    s3.buckets[ENV['S3_BUCKET_NAME']]
  end

  def perform
    @customer = Customer.find(customer_id)
    @master = Master.find(master_id)

    @master.site_progress = 0.1
    @master.save

    for i in 0..10 do
      @master.muni_admin_auth_codes.build(:planner => true, :operator => true)
      @master.muni_admin_auth_codes.build(:operator => true)
      @master.muni_admin_auth_codes.build(:planner => true)
    end

    @master.site_progress = 0.2
    @master.save

    @s3_bucket = s3_bucket()

    # Creating the modifiable administrator pages for the Master.
    @admin_site = create_master_admin_site(@master, @s3_bucket)
    @master.site_progress = 0.2
    @master.save
    @main_site  = create_master_main_site(@master, @s3_bucket)
    @master.site_progress = 0.4
    @master.save
    @error_site = create_master_error_site(@master, @s3_bucket)
    @master.site_progress = 0.5
    @master.save

    muni_admin_attributes = @customer.attributes.slice("email", "name")
    @muni_admin           = MuniAdmin.new(muni_admin_attributes)
    @muni_admin.master    = @master
    @master.site_progress = 0.55
    @master.save

    auths      = @customer.authentications_copy(:master_id => @master.id)
    auths.each { |auth| @muni_admin.authentications << auth }

    @muni_admin.add_roles([:super, :planner, :operator])
    @muni_admin.save!
    @master.site_progress = 0.6
    @master.save

    # Creating the first Deployment, which is a courtesy.
    @deployment              = Deployment.new()
    @deployment.name         = "Deployment 1"
    @deployment.display_name = "Deployment 1"
    @deployment.latitude     = @master.latitude
    @deployment.longitude    = @master.longitude
    @deployment.owner        = @muni_admin
    @deployment.master       = @master
    @deployment.save!
    create_master_deployment_page(@master, @deployment)
    @master.site_progress = 0.8
    @master.save

    # Creating the first Network in the first Deployment, which is a courtesy.
    @network            = Network.new
    @network.master     = @master
    @network.deployment = @deployment
    @network.name       = "Network 1"
    @network.ensure_slug
    @network.save!
    create_master_deployment_network_page(@master, @deployment, @network)

    @master.site_ready = true
    @master.site_progress = 1.0
    @master.save

  rescue Exception => boom
    @admin_site.destroy if @admin_site
    @main_site.destroy if @main_site
    @error_site.destroy if @error_site
    @master.destroy if @master
    @deployment.destroy if @deployment
    @muni_admin.destroy if @muni_admin
  end
end
