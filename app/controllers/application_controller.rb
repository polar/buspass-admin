class ApplicationController < ActionController::Base
  include PageUtils

  protect_from_forgery
  before_filter :base_database

  layout "application"

  def app_name
    "Busme"
  end

  def base_database
      @database            = "#Busme-#{Rails.env}"

      PageUtils.ensure_sites_pages_site
      PageUtils.ensure_master_admin_site_template
      PageUtils.ensure_master_main_site_template

      @master = Master.find_by_host(request.host)
      #MongoMapper.database = @database
      # We try to fill all of these out just in case. Pretty wasteful at this point
      # but can prune according to controller name latter.
      @master = Master.find(params[:master_id]) if params[:master_id]
      @deployment = Deployment.find(params[:deployment_id]) if params[:deployment_id]
      @activement = Activement.find(params[:activement_id]) if params[:activement_id]
      @site = Cms::Site.find(params[:site_id]) if params[:site_id]
      @sites = Cms::Site.where(:master_id => @master.id).all  if @master && @site.nil?
  end

  helper_method :current_customer, :customer_signed_in?

  private

  def current_customer
    @current_customer ||= Customer.find(session[:customer_id]) if session[:customer_id]
  end
  def customer_signed_in?
    ! @current_customer.nil?
  end

  #
  #def default_url_options
  #  puts "default_url_options called"
  #  options = {}
  #  options.merge!(:master_id => @master.id) if @master
  #  options.merge!(:deployment_id => @deployment.id) if @deployment
  #  options.merge!(:activement_id => @activement.id) if @activement
  #  options.merge!(:site_id => @site.id) if @site
  #  options
  #end
end