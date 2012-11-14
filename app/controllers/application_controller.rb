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

  helper_method :current_customer

  def current_customer
    @current_customer ||= Customer.find(session[:customer_id]) if session[:customer_id]
  end

  def authenticate_customer!
    if ! current_customer
      throw(:warden, :path => main_app.new_customer_sessions_path, :notice => "Please sign in." )
    end
  end

  def authorize_customer!(action, obj)
    raise CanCan::AccessDenied if customer_cannot?(action, obj)
  end

  helper_method :current_muni_admin

  def current_muni_admin
    @current_muni_admin ||= MuniAdmin.find(session[:muni_admin_id]) if session[:muni_admin_id]
  end

  def authenticate_muni_admin!
    if ! current_muni_admin
      ActionController::RoutingError
      throw(:warden, :path => main_app.new_muni_admin_sessions_path(:master_id => @master.id), :notice => "Please sign in." )
    end
  end

  def authorize_muni_admin!(action, obj)
    raise CanCan::AccessDenied if muni_admin_cannot?(action, obj)
  end

  helper_method :current_user

  def current_user
    @current_user ||= Customer.find(session[:user_id]) if session[:user_id]
  end

  def authenticate_user!
    if !current_user
      throw(:warden, :path => main_app.new_user_sessions_path, :notice => "Please sign in.")
    end
  end

  def authorize_user!(action, obj)
    raise CanCan::AccessDenied if user_cannot?(action, obj)
  end

  def current_authentication
    @current_authentication ||= Authentication.find(session[:tpauth_id]) if session[:tpauth_id]
  end

  def sign_out(user)
    if user.is_a? Customer
        session[:customer_id] = nil
    elsif user.is_a?  MuniAdmin
        session[:muni_admin_id] = nil
    elsif user.is_a?  User
        session[:user_id] = nil
    else
    end
    session[:tpauth_id] = nil
  end


  def sign_in(user, oauth = nil)
    if user.is_a? Customer
      session[:customer_id] = user.id
    elsif user.is_a?  MuniAdmin
      session[:muni_admin_id] = user.id
    elsif user.is_a?  User
      session[:user_id] = user.id
    else
    end
    oauth ||= user.authentications.first
    session[:tpauth_id] = oauth.id
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