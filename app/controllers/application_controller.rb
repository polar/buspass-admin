class ApplicationController < ActionController::Base
  include PageUtils

  protect_from_forgery
  before_filter :base_database

  #
  # Since we are using the CMS and we direct to the CMS from
  # the standard templates that are correlated to the action name, we must have an empty layout.
  # This is because the ActionView::TemplateRenderer chooses the designated layout before
  # evaluation of the template, as it is evaluating the template *within* the layout. Therefore,
  # we use an empty layout. The selected CMS page will choose the application layout.
  #
  layout false

  def app_name
    "Busme"
  end

  def base_host
    Rails.application.base_host
  end

  def base_database
      @database            = "#Busme-#{Rails.env}"

      @master = Master.find_by_host(request.host)
      #MongoMapper.database = @database
      # We try to fill all of these out just in case. Pretty wasteful at this point
      # but can prune according to controller name latter.
      @master = Master.find(params[:master_id]) if params[:master_id]
      @deployment = Deployment.find(params[:deployment_id]) if params[:deployment_id]
      @activement = Activement.find(params[:activement_id]) if params[:activement_id]

      PageUtils.ensure_sites_pages_site
      PageUtils.ensure_main_error_pages_site
      PageUtils.ensure_master_admin_site_template
      PageUtils.ensure_master_main_site_template
      PageUtils.ensure_master_error_site_template

      @site = Cms::Site.find(params[:site_id]) if params[:site_id]
      @sites = Cms::Site.where(:master_id => @master.id).all  if @master && @site.nil?
  end

  helper_method :current_customer

  def current_customer
    if !@current_customer || @current_customer.id != session[:customer_id]
      @current_customer = Customer.find(session[:customer_id]) if session[:customer_id]
    end
    @current_customer
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
    if !@current_muni_admin || @current_muni_admin.id != session[:muni_admin_id]
      @current_muni_admin = MuniAdmin.find(session[:muni_admin_id]) if session[:muni_admin_id]
    end
    @current_muni_admin
  end

  def authenticate_muni_admin!
    if ! current_muni_admin
      throw(:warden, :path => main_app.new_muni_admin_sessions_path(:master_id => @master.id), :notice => "Please sign in." )
    end
  end

  def authorize_muni_admin!(action, obj)
    raise CanCan::AccessDenied if muni_admin_cannot?(action, obj)
  end

  helper_method :current_user

  def current_user
    if !@current_user || @current_user.id != session[:user_id]
      @current_user = User.find(session[:user_id]) if session[:user_id]
    end
    @current_user
  end

  def authenticate_user!
    if !current_user
      throw(:warden, :path => main_app.new_user_sessions_path(:master_id => @master.id), :notice => "Please sign in.")
    end
  end

  def authorize_user!(action, obj)
    raise CanCan::AccessDenied if user_cannot?(action, obj)
  end

  def current_customer_authentication
    Authentication.find(session[:customer_oauth_id])
  end

  def current_muni_admin_authentication
    Authentication.find(session[:muni_admin_oauth_id])
  end

  def current_user_authentication
    Authentication.find(session[:user_oauth_id])
  end

  def sign_out(user)
    if user.is_a? Customer
      session[:customer_id]       = nil
      session[:customer_oauth_id] = nil
    elsif user.is_a? MuniAdmin
      session[:muni_admin_oauth_id] = nil
      session[:muni_admin_id]       = nil
    elsif user.is_a? User
      session[:user_oauth_id] = nil
      session[:user_id]       = nil
    else
      raise ArgumentError.new("sign_our: user")
    end
  end

  #
  # Programatically signs a user in, and just chooses an arbitrary authentication
  # if nil.
  #
  def sign_in(user, oauth = nil)
    if user.is_a? Customer
      oauth                       ||= user.authentications.first
      if (oauth.customer != user)
        raise ArgumentError.new("Authentication does not match user")
      end
      session[:customer_oauth_id] = oauth.id
      session[:customer_id]       = user.id
    elsif user.is_a? MuniAdmin
      oauth                         ||= user.authentications.first
      if (oauth.muni_admin != user)
        raise ArgumentError.new("Authentication does not match user")
      end
      session[:muni_admin_oauth_id] = oauth.id
      session[:muni_admin_id]       = user.id
    elsif user.is_a? User
      oauth                   ||= user.authentications.first
      if (oauth.user != user)
        raise ArgumentError.new("Authentication does not match user")
      end
      session[:user_oauth_id] = oauth.id
      session[:user_id]       = user.id
    else
      raise ArgumentError.new("sign_in: user")
    end
  end

  helper_method :email_for_intercom, :user_id_for_intercom, :name_for_intercom, :appid_for_intercom,
                :created_at_for_intercom

  def email_for_intercom
    if current_customer
      email = current_customer.email
    elsif current_muni_admin
      email = current_muni_admin.email
    elsif current_user
      email = current_user.email
    else
      email = "guest@busme.com"
    end
  end

  def user_id_for_intercom
    if current_customer
      id = "Customer_#{current_customer.id}"
    elsif current_muni_admin
      id = "MuniAdmin_#{current_muni_admin.id}"
    elsif current_user
      id = "User_#{current_user.id}"
    else
      id = "guest"
    end
  end

  def name_for_intercom
    if current_customer
      id = "Customer_#{current_customer.name}"
    elsif current_muni_admin
      id = "MuniAdmin_#{current_muni_admin.name}"
    elsif current_user
      id = "User_#{current_user.name}"
    else
      id = "John Doe"
    end
  end

  def created_at_for_intercom
    if current_customer
      id = "#{current_customer.created_at}"
    elsif current_muni_admin
      id = "#{current_muni_admin.created_at}"
    elsif current_user
      id = "#{current_user.created_at}"
    else
      id = "#{Time.now.to_i}"
    end
  end

  def appid_for_intercom
    ENV['INTERCOM_APPID']
  end

  def s3_bucket
    s3 = AWS::S3.new(
        :access_key_id => ENV['AWS_ACCESS_KEY_ID'],
        :secret_access_key => ENV['AWS_SECRET_ACCESS_KEY'])
    s3.buckets[ENV['S3_BUCKET_NAME']]
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

  #
  # Rescue Strategy.
  #
  # If the controller experiences an exception before it renders the
  # template, we rescue the error with one of the following functions
  # depending on the context.
  #

  ##
  # This rescue function is for the context of a controller handing the
  # main busme.us site. (i.e. website and customer management.)
  #
  def rescue_main_error_page(boom)
    @error_site = Cms::Site.find_by_identifier("busme-main-error")
    @error_page = rescue_main_process_error(@error_site, boom)
    if @error_page
      render :inline => @error_page.render(view_context, :status => @error_page.error_status, :content_type => "content/html")
    else
      # We record this error since it is so unexpected
      page_error = PageError.new({
                                     :request_url => request.url,
                                     :params     => params,
                                     :error      => "rescue_with_main_error_page: Could not find error page for #{boom}",
                                     :backtrace  => boom.backtrace,
                                     :master     => @master,
                                     :customer   => current_customer,
                                     :muni_admin => current_muni_admin,
                                     :user       => current_user
                                 })
      page_error.save
      render "public/500.html", :status => 500
    end
  end

  ##
  # This rescue handler is for the context of a controller handing the
  # administration of a particular master.
  #
  def rescue_master_admin_error_page(boom)
    if @master
      @error_site = @master.error_site
      @error_page = rescue_master_admin_process_error(@error_site, boom)
      if @error_page
        render :inline => @error_page.render(view_context, :status => @error_page.error_status, :content_type => "content/html")
      else
        # We record this error since it is so unexpected
        page_error = PageError.new({
                                       :request_url => request.url,
                                       :params     => params,
                                       :error      => "rescue_master_admin_error_page: Could not find error page for #{boom}",
                                       :backtrace  => boom.backtrace,
                                       :master     => @master,
                                       :customer   => current_customer,
                                       :muni_admin => current_muni_admin,
                                       :user       => current_user
                                   })
        page_error.save
        render "public/500.html", :status => 500
      end
    else
      render "public/404.html", :status => 404
    end
  end

  ##
  # This rescue handler is for the context of a controller handling the
  # front user facing site of a particular master.
  #
  def rescue_master_error_page(boom)
    if @master
      @error_site = @master.error_site
      @error_page = rescue_master_main_process_error(@error_site, boom)
      if @error_page
        render :inline => @error_page.render(view_context, :status => @error_page.error_status, :content_type => "content/html")
      else
        # We record this error since it is so unexpected
        page_error = PageError.new({
                                       :request_url => request.url,
                                       :params     => params,
                                       :error      => "rescue_master_error_page: Could not find error page for #{boom}",
                                       :backtrace  => boom.backtrace,
                                       :master     => @master,
                                       :customer   => current_customer,
                                       :muni_admin => current_muni_admin,
                                       :user       => current_user
                                   })
        page_error.save
        render "public/500.html", :status => 500
      end
    else
      render "public/404.html", :status => 404
    end
  end

  def rescue_main_process_error(error_site, boom)
    rescue_process_error(error_site, "/", boom)
  end

  def rescue_master_admin_process_error(error_site, boom)
    rescue_process_error(error_site, "/admins", boom)
  end

  def rescue_master_main_process_error(error_site, boom)
    rescue_process_error(error_site, "/users", boom)
  end
  
  #
  # This function finds the correct page according to the exception
  # from the given CMS (error pages) site. We log a PageError if
  # we do not find it, and hopefully te "internal_error" page
  # is there.
  #
  def rescue_process_error(error_site, prefix, boom)
    error_page = nil
    if boom.is_a? CanCan::AccessDenied
        error_page = error_site.pages.find_by_fullpath("/#{prefix}/permission_denied".squeeze("/"))
    elsif boom.is_a? NotFoundError
        error_page = error_site.pages.find_by_fullpath("/#{prefix}/not_found".squeeze("/"))
    else
        # We record this error since it is so unexpected
        page_error = PageError.new({
                                       :request_url => request.url,
                                       :params     => params,
                                       :error      => boom.to_s,
                                       :backtrace  => boom.backtrace,
                                       :master     => @master,
                                       :customer   => current_customer,
                                       :muni_admin => current_muni_admin,
                                       :user       => current_user
                                   })
        page_error.save
        error_page = error_site.pages.find_by_fullpath("/#{prefix}/internal_error".squeeze("/"))
    end
    return error_page
  end

end